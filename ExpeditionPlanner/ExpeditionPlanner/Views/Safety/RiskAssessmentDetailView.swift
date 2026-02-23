import SwiftUI
import SwiftData

struct RiskAssessmentDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let assessment: RiskAssessment
    let expedition: Expedition
    var viewModel: RiskAssessmentViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header with risk rating
            Section {
                headerView
            }

            // Risk Matrix Display
            Section {
                riskMatrixSection
            } header: {
                Text("Risk Assessment")
            }

            // Mitigation Strategy
            if !assessment.mitigationStrategy.isEmpty {
                Section {
                    Text(assessment.mitigationStrategy)
                } header: {
                    Label("Mitigation Strategy", systemImage: "shield.checkered")
                }
            }

            // Prevention Measures
            if !assessment.preventionMeasures.isEmpty {
                Section {
                    Text(assessment.preventionMeasures)
                } header: {
                    Label("Prevention Measures", systemImage: "hand.raised")
                }
            }

            // Emergency Procedure
            if !assessment.emergencyProcedure.isEmpty {
                Section {
                    Text(assessment.emergencyProcedure)
                        .foregroundStyle(.red.opacity(0.9))
                } header: {
                    Label("Emergency Procedure", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            // Context
            if assessment.location != nil || assessment.seasonalNotes != nil {
                Section {
                    if let location = assessment.location, !location.isEmpty {
                        LabeledContent("Location", value: location)
                    }
                    if let seasonal = assessment.seasonalNotes, !seasonal.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seasonal Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(seasonal)
                        }
                    }
                } header: {
                    Text("Context")
                }
            }

            // Description
            if !assessment.riskDescription.isEmpty {
                Section {
                    Text(assessment.riskDescription)
                } header: {
                    Text("Description")
                }
            }

            // Notes
            if !assessment.notes.isEmpty {
                Section {
                    Text(assessment.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Source
            if let source = assessment.sourceNotes, !source.isEmpty {
                Section {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Source")
                }
            }

            // Status
            Section {
                statusSection
            } header: {
                Text("Status")
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Risk Assessment", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Risk Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                RiskAssessmentFormView(
                    mode: .edit(assessment),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Risk Assessment?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAssessment(assessment, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            // Risk indicator
            VStack {
                Image(systemName: assessment.riskRating.icon)
                    .font(.title)
                    .foregroundStyle(colorForRating)
                Text("\(assessment.riskScore)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 60, height: 60)
            .background(colorForRating.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(assessment.title)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: assessment.hazardType.icon)
                        .font(.caption)
                    Text(assessment.hazardType.rawValue)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)

                Text(assessment.riskRating.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForRating.opacity(0.2))
                    .foregroundStyle(colorForRating)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Risk Matrix Section

    private var riskMatrixSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Likelihood")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(assessment.likelihood.rawValue)
                        .font(.headline)
                }

                Spacer()

                Image(systemName: "multiply")
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Severity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(assessment.severity.rawValue)
                        .font(.headline)
                }

                Spacer()

                Image(systemName: "equal")
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Risk Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(assessment.riskScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(colorForRating)
                }
            }

            // Visual risk level bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForRating)
                        .frame(width: geometry.size.width * riskPercentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            Toggle("Addressed", isOn: Binding(
                get: { assessment.isAddressed },
                set: { newValue in
                    assessment.isAddressed = newValue
                    viewModel.updateAssessment(assessment, in: expedition)
                }
            ))

            if let reviewDate = assessment.reviewDate {
                LabeledContent("Last Review") {
                    Text(reviewDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    // MARK: - Helpers

    private var colorForRating: Color {
        switch assessment.riskRating.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .secondary
        }
    }

    private var riskPercentage: Double {
        // Max risk score is 25 (5x5)
        Double(assessment.riskScore) / 25.0
    }
}

#Preview {
    NavigationStack {
        RiskAssessmentDetailView(
            assessment: {
                let risk = RiskAssessment(
                    title: "Bear Encounter",
                    hazardType: .wildlife,
                    likelihood: .medium,
                    severity: .high
                )
                risk.riskDescription = "Risk of encountering bears in the backcountry."
                risk.mitigationStrategy = "Carry bear spray, use bear canisters for food storage."
                risk.emergencyProcedure = "Back away slowly, do not run. Use bear spray if charged."
                risk.location = "Brooks Range, AK"
                return risk
            }(),
            expedition: Expedition(name: "Test"),
            viewModel: RiskAssessmentViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
