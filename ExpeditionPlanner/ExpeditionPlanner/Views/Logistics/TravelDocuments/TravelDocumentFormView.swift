import SwiftUI
import SwiftData

enum TravelDocumentFormMode {
    case create
    case edit(TravelDocument)
}

struct TravelDocumentFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: TravelDocumentFormMode
    let expedition: Expedition
    var viewModel: TravelDocumentViewModel

    // Form fields
    @State private var documentType: DocumentType = .passport
    @State private var holderName: String = ""
    @State private var documentNumber: String = ""
    @State private var issuingCountry: String = ""

    @State private var issueDate: Date = Date()
    @State private var hasIssueDate: Bool = false
    @State private var expiryDate: Date = Date()
    @State private var hasExpiryDate: Bool = false

    @State private var visaType: String = ""
    @State private var destinationCountry: String = ""

    @State private var applicationStatus: ApplicationStatus = .notStarted
    @State private var applicationURL: String = ""
    @State private var processingTime: String = ""

    @State private var costText: String = ""
    @State private var costCurrency: String = "USD"

    @State private var documentsNeeded: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingDocument: TravelDocument? {
        if case .edit(let document) = mode {
            return document
        }
        return nil
    }

    var body: some View {
        Form {
            documentInfoSection
            datesSection
            travelDetailsSection
            applicationSection
            costSection
            requiredDocumentsSection
            notesSection
        }
        .navigationTitle(isEditing ? "Edit Travel Document" : "New Travel Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveDocument()
                }
                .disabled(holderName.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var documentInfoSection: some View {
        Section {
            Picker("Document Type", selection: $documentType) {
                ForEach(DocumentType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            TextField("Holder Name", text: $holderName)

            TextField("Document Number", text: $documentNumber)

            TextField("Issuing Country", text: $issuingCountry)
        } header: {
            Text("Document Info")
        }
    }

    private var datesSection: some View {
        Section {
            Toggle("Has Issue Date", isOn: $hasIssueDate)

            if hasIssueDate {
                DatePicker(
                    "Issue Date",
                    selection: $issueDate,
                    displayedComponents: .date
                )
            }

            Toggle("Has Expiry Date", isOn: $hasExpiryDate)

            if hasExpiryDate {
                DatePicker(
                    "Expiry Date",
                    selection: $expiryDate,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Dates")
        }
    }

    private var travelDetailsSection: some View {
        Section {
            TextField("Visa Type", text: $visaType)

            TextField("Destination Country", text: $destinationCountry)
        } header: {
            Text("Travel Details")
        }
    }

    private var applicationSection: some View {
        Section {
            Picker("Status", selection: $applicationStatus) {
                ForEach(ApplicationStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }

            TextField("Application URL", text: $applicationURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Processing Time", text: $processingTime)
        } header: {
            Text("Application")
        }
    }

    private var costSection: some View {
        Section {
            TextField("Cost", text: $costText)
                .keyboardType(.decimalPad)

            TextField("Currency", text: $costCurrency)
                .textInputAutocapitalization(.characters)
        } header: {
            Text("Cost")
        }
    }

    private var requiredDocumentsSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Required Documents")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $documentsNeeded)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Required Documents")
        } footer: {
            Text("Enter comma-separated list of required documents.")
        }
    }

    private var notesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Notes")
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let document = existingDocument else { return }

        documentType = document.documentType
        holderName = document.holderName
        documentNumber = document.documentNumber
        issuingCountry = document.issuingCountry

        if let date = document.issueDate {
            issueDate = date
            hasIssueDate = true
        }
        if let date = document.expiryDate {
            expiryDate = date
            hasExpiryDate = true
        }

        visaType = document.visaType
        destinationCountry = document.destinationCountry

        applicationStatus = document.applicationStatus
        applicationURL = document.applicationURL
        processingTime = document.processingTime

        if let cost = document.cost {
            costText = "\(cost)"
        }
        costCurrency = document.costCurrency

        documentsNeeded = document.documentsNeeded
        notes = document.notes
    }

    // MARK: - Save

    private func saveDocument() {
        let costDecimal = Decimal(string: costText)

        if let existing = existingDocument {
            existing.documentType = documentType
            existing.holderName = holderName
            existing.documentNumber = documentNumber
            existing.issuingCountry = issuingCountry
            existing.issueDate = hasIssueDate ? issueDate : nil
            existing.expiryDate = hasExpiryDate ? expiryDate : nil
            existing.visaType = visaType
            existing.destinationCountry = destinationCountry
            existing.applicationStatus = applicationStatus
            existing.applicationURL = applicationURL
            existing.processingTime = processingTime
            existing.cost = costDecimal
            existing.costCurrency = costCurrency
            existing.documentsNeeded = documentsNeeded
            existing.notes = notes

            viewModel.updateDocument(existing, in: expedition)
        } else {
            let document = TravelDocument(documentType: documentType, holderName: holderName)
            document.documentNumber = documentNumber
            document.issuingCountry = issuingCountry
            document.issueDate = hasIssueDate ? issueDate : nil
            document.expiryDate = hasExpiryDate ? expiryDate : nil
            document.visaType = visaType
            document.destinationCountry = destinationCountry
            document.applicationStatus = applicationStatus
            document.applicationURL = applicationURL
            document.processingTime = processingTime
            document.cost = costDecimal
            document.costCurrency = costCurrency
            document.documentsNeeded = documentsNeeded
            document.notes = notes

            viewModel.addDocument(document, to: expedition)
        }

        dismiss()
    }
}
