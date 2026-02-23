import SwiftUI
import SwiftData

enum RiskAssessmentFormMode {
    case create
    case edit(RiskAssessment)
}

struct RiskAssessmentFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: RiskAssessmentFormMode
    let expedition: Expedition
    var viewModel: RiskAssessmentViewModel

    // Form fields
    @State private var title: String = ""
    @State private var riskDescription: String = ""
    @State private var hazardType: HazardType = .terrain
    @State private var likelihood: RiskLevel = .medium
    @State private var severity: RiskLevel = .medium
    @State private var mitigationStrategy: String = ""
    @State private var preventionMeasures: String = ""
    @State private var emergencyProcedure: String = ""
    @State private var location: String = ""
    @State private var seasonalNotes: String = ""
    @State private var sourceNotes: String = ""
    @State private var isAddressed: Bool = false
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "Edit Risk" : "New Risk"
    }

    private var existingAssessment: RiskAssessment? {
        if case .edit(let assessment) = mode {
            return assessment
        }
        return nil
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Title", text: $title)

                Picker("Hazard Type", selection: $hazardType) {
                    ForEach(HazardType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $riskDescription)
                        .frame(minHeight: 60)
                }
            } header: {
                Text("Hazard Information")
            }

            // Risk Assessment
            Section {
                Picker("Likelihood", selection: $likelihood) {
                    ForEach(RiskLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                Picker("Severity", selection: $severity) {
                    ForEach(RiskLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }

                // Live risk score preview
                HStack {
                    Text("Risk Score")
                    Spacer()
                    Text("\(likelihood.value * severity.value)")
                        .font(.headline)
                        .foregroundStyle(colorForScore(likelihood.value * severity.value))
                    Text(ratingLabel(for: likelihood.value * severity.value))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForScore(likelihood.value * severity.value).opacity(0.2))
                        .clipShape(Capsule())
                }
            } header: {
                Text("Risk Assessment")
            } footer: {
                Text("Risk Score = Likelihood (\(likelihood.value)) x Severity (\(severity.value))")
            }

            // Mitigation
            Section {
                VStack(alignment: .leading) {
                    Text("Mitigation Strategy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $mitigationStrategy)
                        .frame(minHeight: 80)
                }

                VStack(alignment: .leading) {
                    Text("Prevention Measures")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $preventionMeasures)
                        .frame(minHeight: 60)
                }
            } header: {
                Label("Mitigation", systemImage: "shield.checkered")
            }

            // Emergency Procedure
            Section {
                VStack(alignment: .leading) {
                    Text("Emergency Procedure")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $emergencyProcedure)
                        .frame(minHeight: 80)
                }
            } header: {
                Label("Emergency Response", systemImage: "exclamationmark.triangle")
            } footer: {
                Text("Document the specific actions to take if this hazard is encountered.")
            }

            // Context
            Section {
                TextField("Location", text: $location)

                VStack(alignment: .leading) {
                    Text("Seasonal Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $seasonalNotes)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Context")
            }

            // Status
            Section {
                Toggle("Risk Addressed", isOn: $isAddressed)
            } header: {
                Text("Status")
            } footer: {
                Text("Mark as addressed when mitigation measures are in place.")
            }

            // Notes & Source
            Section {
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 40)
                }

                VStack(alignment: .leading) {
                    Text("Source/Reference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $sourceNotes)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Additional Information")
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveAssessment()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let assessment = existingAssessment else { return }

        title = assessment.title
        riskDescription = assessment.riskDescription
        hazardType = assessment.hazardType
        likelihood = assessment.likelihood
        severity = assessment.severity
        mitigationStrategy = assessment.mitigationStrategy
        preventionMeasures = assessment.preventionMeasures
        emergencyProcedure = assessment.emergencyProcedure
        location = assessment.location ?? ""
        seasonalNotes = assessment.seasonalNotes ?? ""
        sourceNotes = assessment.sourceNotes ?? ""
        isAddressed = assessment.isAddressed
        notes = assessment.notes
    }

    // MARK: - Save

    private func saveAssessment() {
        if let existing = existingAssessment {
            // Update existing
            existing.title = title
            existing.riskDescription = riskDescription
            existing.hazardType = hazardType
            existing.likelihood = likelihood
            existing.severity = severity
            existing.mitigationStrategy = mitigationStrategy
            existing.preventionMeasures = preventionMeasures
            existing.emergencyProcedure = emergencyProcedure
            existing.location = location.isEmpty ? nil : location
            existing.seasonalNotes = seasonalNotes.isEmpty ? nil : seasonalNotes
            existing.sourceNotes = sourceNotes.isEmpty ? nil : sourceNotes
            existing.isAddressed = isAddressed
            existing.notes = notes
            existing.reviewDate = Date()

            viewModel.updateAssessment(existing, in: expedition)
        } else {
            // Create new
            let assessment = RiskAssessment(
                title: title,
                hazardType: hazardType,
                likelihood: likelihood,
                severity: severity
            )
            assessment.riskDescription = riskDescription
            assessment.mitigationStrategy = mitigationStrategy
            assessment.preventionMeasures = preventionMeasures
            assessment.emergencyProcedure = emergencyProcedure
            assessment.location = location.isEmpty ? nil : location
            assessment.seasonalNotes = seasonalNotes.isEmpty ? nil : seasonalNotes
            assessment.sourceNotes = sourceNotes.isEmpty ? nil : sourceNotes
            assessment.isAddressed = isAddressed
            assessment.notes = notes

            viewModel.addAssessment(assessment, to: expedition)
        }

        dismiss()
    }

    // MARK: - Helpers

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...12: return .orange
        default: return .red
        }
    }

    private func ratingLabel(for score: Int) -> String {
        switch score {
        case 1...3: return "Low"
        case 4...6: return "Medium"
        case 7...12: return "High"
        default: return "Critical"
        }
    }
}

#Preview {
    NavigationStack {
        RiskAssessmentFormView(
            mode: .create,
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
