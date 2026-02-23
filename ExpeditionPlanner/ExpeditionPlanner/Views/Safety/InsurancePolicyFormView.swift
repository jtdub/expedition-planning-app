import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

enum InsuranceFormMode {
    case add
    case edit(InsurancePolicy)
}

struct InsurancePolicyFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: InsuranceFormMode
    let expedition: Expedition
    var viewModel: InsuranceViewModel

    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var insuranceType: InsuranceType = .travelMedical
    @State private var coverageStartDate: Date = Date()
    @State private var coverageEndDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @State private var hasDateRange = true
    @State private var emergencyPhone = ""
    @State private var claimsPhone = ""
    @State private var coverageAmountString = ""
    @State private var deductibleString = ""
    @State private var currency = "USD"
    @State private var notes = ""
    @State private var documentURL = ""

    // Participant selection
    @State private var selectedParticipantIds: Set<UUID> = []

    // Document attachment
    @State private var attachedDocumentData: Data?
    @State private var attachedDocumentName: String?
    @State private var attachedDocumentType: String?
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingPolicy: InsurancePolicy? {
        if case .edit(let policy) = mode { return policy }
        return nil
    }

    private var availableParticipants: [Participant] {
        (expedition.participants ?? []).sorted { $0.name < $1.name }
    }

    var body: some View {
        Form {
            Section {
                TextField("Provider Name", text: $provider)
                TextField("Policy Number", text: $policyNumber)

                Picker("Type", selection: $insuranceType) {
                    ForEach(InsuranceType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            } header: {
                Text("Policy Information")
            }

            Section {
                Toggle("Set Coverage Dates", isOn: $hasDateRange)

                if hasDateRange {
                    DatePicker("Start Date", selection: $coverageStartDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $coverageEndDate, displayedComponents: .date)
                }
            } header: {
                Text("Coverage Period")
            }

            Section {
                HStack {
                    TextField("Coverage Amount", text: $coverageAmountString)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("CAD").tag("CAD")
                        Text("AUD").tag("AUD")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                HStack {
                    TextField("Deductible", text: $deductibleString)
                        .keyboardType(.decimalPad)
                    Text(currency)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Coverage Details")
            }

            // Covered Participants Section
            if !availableParticipants.isEmpty {
                Section {
                    ForEach(availableParticipants) { participant in
                        Button {
                            toggleParticipant(participant)
                        } label: {
                            HStack {
                                Image(systemName: participant.role.icon)
                                    .foregroundStyle(.secondary)
                                Text(participant.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedParticipantIds.contains(participant.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }

                    if selectedParticipantIds.isEmpty {
                        Text("No participants selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(selectedParticipantIds.count) participant(s) covered")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Covered Participants")
                } footer: {
                    Text("Select which expedition participants are covered by this policy.")
                }
            }

            Section {
                TextField("Emergency Phone", text: $emergencyPhone)
                    .keyboardType(.phonePad)
                TextField("Claims Phone", text: $claimsPhone)
                    .keyboardType(.phonePad)
            } header: {
                Text("Contact Numbers")
            } footer: {
                Text("Keep emergency numbers accessible in case of an incident.")
            }

            // Document Attachment Section
            Section {
                TextField("Document URL (optional)", text: $documentURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let docName = attachedDocumentName {
                    HStack {
                        Image(systemName: documentIcon)
                            .foregroundStyle(.blue)
                        Text(docName)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            clearAttachment()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Attach Document", systemImage: "doc.badge.plus")
                    }

                    Spacer()

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Label("Photo", systemImage: "photo.badge.plus")
                    }
                }
            } header: {
                Text("Documentation")
            } footer: {
                Text("Attach a PDF or photo of your policy document for offline access.")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }

            // Type description
            Section {
                Text(insuranceType.typeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About \(insuranceType.rawValue)")
            }
        }
        .navigationTitle(isEditing ? "Edit Policy" : "Add Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePolicy()
                }
                .disabled(provider.isEmpty)
            }
        }
        .onAppear {
            if let policy = editingPolicy {
                loadPolicy(policy)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                await loadPhoto(from: newValue)
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentImport(result)
        }
    }

    // MARK: - Document Icon

    private var documentIcon: String {
        guard let type = attachedDocumentType else { return "doc" }
        if type.contains("pdf") {
            return "doc.richtext"
        } else if type.contains("image") || type.contains("png") || type.contains("jpeg") {
            return "photo"
        }
        return "doc"
    }

    // MARK: - Participant Selection

    private func toggleParticipant(_ participant: Participant) {
        if selectedParticipantIds.contains(participant.id) {
            selectedParticipantIds.remove(participant.id)
        } else {
            selectedParticipantIds.insert(participant.id)
        }
    }

    // MARK: - Document Handling

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                attachedDocumentData = data
                attachedDocumentName = "Photo_\(Date().formatted(.dateTime.year().month().day())).jpg"
                attachedDocumentType = "image/jpeg"
            }
        }
    }

    private func handleDocumentImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            if let data = try? Data(contentsOf: url) {
                attachedDocumentData = data
                attachedDocumentName = url.lastPathComponent
                attachedDocumentType = url.pathExtension == "pdf" ? "application/pdf" : "image/\(url.pathExtension)"
            }
        case .failure:
            break
        }
    }

    private func clearAttachment() {
        attachedDocumentData = nil
        attachedDocumentName = nil
        attachedDocumentType = nil
        selectedPhotoItem = nil
    }

    // MARK: - Load/Save

    private func loadPolicy(_ policy: InsurancePolicy) {
        provider = policy.provider
        policyNumber = policy.policyNumber
        insuranceType = policy.insuranceType
        if let start = policy.coverageStartDate, let end = policy.coverageEndDate {
            coverageStartDate = start
            coverageEndDate = end
            hasDateRange = true
        } else {
            hasDateRange = false
        }
        emergencyPhone = policy.emergencyPhone ?? ""
        claimsPhone = policy.claimsPhone ?? ""
        if let amount = policy.coverageAmount {
            coverageAmountString = "\(amount)"
        }
        if let deductible = policy.deductible {
            deductibleString = "\(deductible)"
        }
        currency = policy.currency
        notes = policy.notes
        documentURL = policy.documentURL ?? ""

        // Load covered participants
        selectedParticipantIds = Set(policy.coveredParticipantUUIDs)

        // Load attached document
        attachedDocumentData = policy.attachedDocumentData
        attachedDocumentName = policy.attachedDocumentName
        attachedDocumentType = policy.attachedDocumentType
    }

    private func savePolicy() {
        let policy: InsurancePolicy
        if let existing = editingPolicy {
            policy = existing
        } else {
            policy = InsurancePolicy()
        }

        policy.provider = provider
        policy.policyNumber = policyNumber
        policy.insuranceType = insuranceType
        policy.coverageStartDate = hasDateRange ? coverageStartDate : nil
        policy.coverageEndDate = hasDateRange ? coverageEndDate : nil
        policy.emergencyPhone = emergencyPhone.isEmpty ? nil : emergencyPhone
        policy.claimsPhone = claimsPhone.isEmpty ? nil : claimsPhone
        policy.coverageAmount = Decimal(string: coverageAmountString)
        policy.deductible = Decimal(string: deductibleString)
        policy.currency = currency
        policy.notes = notes
        policy.documentURL = documentURL.isEmpty ? nil : documentURL

        // Save covered participants as UUIDs
        policy.coveredParticipantUUIDs = Array(selectedParticipantIds)

        // Save attached document
        policy.attachedDocumentData = attachedDocumentData
        policy.attachedDocumentName = attachedDocumentName
        policy.attachedDocumentType = attachedDocumentType

        if isEditing {
            viewModel.updatePolicy(policy, in: expedition)
        } else {
            viewModel.addPolicy(policy, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        InsurancePolicyFormView(
            mode: .add,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: InsuranceViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
