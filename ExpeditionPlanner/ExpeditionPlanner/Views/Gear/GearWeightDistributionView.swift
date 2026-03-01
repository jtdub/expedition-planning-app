import SwiftUI
import SwiftData

struct GearWeightDistributionView: View {
    var viewModel: GearViewModel

    @AppStorage("weightUnit")
    private var weightUnit: WeightUnit = .kilograms

    var body: some View {
        List {
            // Summary header
            summarySection

            // Per-participant breakdown
            if !viewModel.weightByParticipant.isEmpty {
                participantSection
            }

            // Unassigned group gear
            if !viewModel.unassignedGroupItems.isEmpty {
                unassignedSection
            }
        }
        .navigationTitle("Weight Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            LabeledContent("Group Gear") {
                Text(viewModel.formatWeight(viewModel.groupWeightGrams, unit: weightUnit))
                    .fontWeight(.medium)
            }

            LabeledContent("Unassigned") {
                Text(viewModel.formatWeight(viewModel.unassignedGroupWeightGrams, unit: weightUnit))
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.unassignedGroupItems.isEmpty ? Color.secondary : Color.orange)
            }

            LabeledContent("Group Items") {
                Text("\(viewModel.groupItems.count)")
            }
        } header: {
            Text("Overview")
        }
    }

    // MARK: - Participant Section

    private var participantSection: some View {
        Section {
            let maxWeight = viewModel.weightByParticipant.map(\.weightGrams).max() ?? 1

            ForEach(viewModel.weightByParticipant, id: \.participant.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.participant.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.formatWeight(entry.weightGrams, unit: weightUnit))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geometry in
                        let fraction = maxWeight > 0 ? entry.weightGrams / maxWeight : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.blue.opacity(0.7))
                            .frame(width: geometry.size.width * fraction, height: 8)
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("By Participant")
        }
    }

    // MARK: - Unassigned Section

    private var unassignedSection: some View {
        Section {
            ForEach(viewModel.unassignedGroupItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        Label(item.category.rawValue, systemImage: item.category.icon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let weight = item.totalWeight {
                        Text(viewModel.formatWeight(weight.value, unit: weightUnit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Unassigned Group Gear")
        } footer: {
            Text("Assign carriers in the gear item editor.")
        }
    }
}

#Preview {
    NavigationStack {
        GearWeightDistributionView(
            viewModel: {
                let expedition = Expedition(name: "Test")
                // swiftlint:disable:next force_try
                let container = try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                return GearViewModel(
                    expedition: expedition,
                    modelContext: container.mainContext
                )
            }()
        )
    }
}
