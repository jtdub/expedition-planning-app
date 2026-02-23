import SwiftUI
import SwiftData

struct InsuranceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: InsuranceViewModel?
    @State private var showingAddSheet = false
    @State private var selectedPolicy: InsurancePolicy?
    @State private var filterType: InsuranceType?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                insuranceList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Insurance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All Types") {
                        filterType = nil
                    }
                    ForEach(InsuranceType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            filterType = type
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    InsurancePolicyFormView(mode: .add, expedition: expedition, viewModel: viewModel)
                }
            }
        }
        .sheet(item: $selectedPolicy) { policy in
            if let viewModel = viewModel {
                NavigationStack {
                    InsurancePolicyDetailView(
                        policy: policy,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InsuranceViewModel(modelContext: modelContext)
            }
            viewModel?.loadPolicies(for: expedition)
        }
    }

    @ViewBuilder
    private func insuranceList(viewModel: InsuranceViewModel) -> some View {
        let filteredPolicies = filterType == nil
            ? viewModel.policies
            : viewModel.policies.filter { $0.insuranceType == filterType }

        if filteredPolicies.isEmpty {
            ContentUnavailableView {
                Label("No Insurance Policies", systemImage: "shield.slash")
            } description: {
                Text("Add insurance policies to track coverage for your expedition.")
            } actions: {
                Button("Add Policy") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                // Summary Section
                if filterType == nil {
                    Section {
                        coverageSummary(viewModel: viewModel)
                    }
                }

                // Attention Needed
                let needsAttention = viewModel.policiesNeedingAttention()
                if !needsAttention.isEmpty && filterType == nil {
                    Section {
                        ForEach(needsAttention) { policy in
                            InsurancePolicyRow(policy: policy)
                                .onTapGesture {
                                    selectedPolicy = policy
                                }
                        }
                    } header: {
                        Label("Needs Attention", systemImage: "exclamationmark.triangle")
                    }
                }

                // Active Policies
                let activePolicies = filteredPolicies.filter { $0.isActive && !$0.isExpiringSoon }
                if !activePolicies.isEmpty {
                    Section {
                        ForEach(activePolicies) { policy in
                            InsurancePolicyRow(policy: policy)
                                .onTapGesture {
                                    selectedPolicy = policy
                                }
                        }
                        .onDelete { indexSet in
                            deletePolicy(at: indexSet, from: activePolicies, viewModel: viewModel)
                        }
                    } header: {
                        Text("Active Policies")
                    }
                }

                // Inactive/Expired
                let inactivePolicies = filteredPolicies.filter { !$0.isActive }
                if !inactivePolicies.isEmpty {
                    Section {
                        ForEach(inactivePolicies) { policy in
                            InsurancePolicyRow(policy: policy)
                                .onTapGesture {
                                    selectedPolicy = policy
                                }
                        }
                        .onDelete { indexSet in
                            deletePolicy(at: indexSet, from: inactivePolicies, viewModel: viewModel)
                        }
                    } header: {
                        Text("Inactive")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func coverageSummary(viewModel: InsuranceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CoverageIndicator(
                    title: "Medical",
                    isActive: viewModel.hasMedicalCoverage,
                    icon: "cross.case.fill"
                )
                Spacer()
                CoverageIndicator(
                    title: "Evacuation",
                    isActive: viewModel.hasEvacuationCoverage,
                    icon: "airplane.departure"
                )
                Spacer()
                CoverageIndicator(
                    title: "SAR",
                    isActive: viewModel.hasSearchRescueCoverage,
                    icon: "figure.wave"
                )
            }

            if viewModel.expiringSoonCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("\(viewModel.expiringSoonCount) policy expiring soon")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func deletePolicy(
        at indexSet: IndexSet,
        from policies: [InsurancePolicy],
        viewModel: InsuranceViewModel
    ) {
        for index in indexSet {
            viewModel.deletePolicy(policies[index], from: expedition)
        }
    }
}

// MARK: - Coverage Indicator

struct CoverageIndicator: View {
    let title: String
    let isActive: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isActive ? .green : .secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(isActive ? .primary : .secondary)
            Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundStyle(isActive ? .green : .red)
        }
    }
}

// MARK: - Policy Row

struct InsurancePolicyRow: View {
    let policy: InsurancePolicy

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: policy.insuranceType.icon)
                .font(.title2)
                .foregroundStyle(colorForType(policy.insuranceType))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(policy.provider)
                    .font(.headline)
                Text(policy.insuranceType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                statusBadge
                if let amount = policy.coverageAmount {
                    Text(formatCurrency(amount, code: policy.currency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var statusBadge: some View {
        if policy.isExpired {
            Text("Expired")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        } else if policy.isExpiringSoon {
            Text("Expiring")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        } else if policy.isActive {
            Text("Active")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        } else {
            Text("Pending")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.gray.opacity(0.2))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
        }
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }

    private func colorForType(_ type: InsuranceType) -> Color {
        switch type.color {
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "yellow": return .yellow
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        InsuranceListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, InsurancePolicy.self], inMemory: true)
}
