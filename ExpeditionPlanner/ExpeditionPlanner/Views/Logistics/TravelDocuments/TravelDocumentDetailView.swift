import SwiftUI
import SwiftData

struct TravelDocumentDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let document: TravelDocument
    let expedition: Expedition
    var viewModel: TravelDocumentViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Document Info
            Section {
                documentInfoSection
            } header: {
                Text("Document Info")
            }

            // Visa / Travel
            if hasVisaInfo {
                Section {
                    visaTravelSection
                } header: {
                    Label("Visa / Travel", systemImage: "airplane")
                }
            }

            // Application
            Section {
                applicationSection
            } header: {
                Label("Application", systemImage: "doc.text")
            }

            // Required Documents
            if !document.documentsNeededList.isEmpty {
                Section {
                    requiredDocumentsSection
                } header: {
                    Text("Required Documents")
                }
            }

            // Notes
            if !document.notes.isEmpty {
                Section {
                    Text(document.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Travel Document", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Document Details")
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
                TravelDocumentFormView(
                    mode: .edit(document),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Travel Document?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteDocument(document, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: document.documentType.icon)
                    .font(.title)
                    .foregroundStyle(colorForStatus)
            }
            .frame(width: 60, height: 60)
            .background(colorForStatus.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(document.applicationStatus.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForStatus.opacity(0.2))
                    .foregroundStyle(colorForStatus)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Document Info

    private var documentInfoSection: some View {
        VStack(spacing: 8) {
            LabeledContent("Type", value: document.documentType.rawValue)

            if !document.holderName.isEmpty {
                LabeledContent("Holder Name", value: document.holderName)
            }

            if !document.documentNumber.isEmpty {
                LabeledContent("Document Number", value: document.documentNumber)
            }

            if !document.issuingCountry.isEmpty {
                LabeledContent("Issuing Country", value: document.issuingCountry)
            }

            if let issueDate = document.issueDate {
                LabeledContent("Issue Date") {
                    Text(issueDate.formatted(date: .abbreviated, time: .omitted))
                }
            }

            if let expiryDate = document.expiryDate {
                LabeledContent("Expiry Date") {
                    HStack(spacing: 4) {
                        Text(expiryDate.formatted(date: .abbreviated, time: .omitted))
                        if document.isExpired {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        } else if document.isExpiringSoon {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            if let daysLeft = document.daysUntilExpiry {
                if document.isExpired {
                    LabeledContent("Status") {
                        Text("Expired \(abs(daysLeft)) days ago")
                            .foregroundStyle(.red)
                    }
                } else {
                    LabeledContent("Days Until Expiry") {
                        Text("\(daysLeft) days")
                            .foregroundStyle(document.isExpiringSoon ? .orange : .primary)
                    }
                }
            }
        }
    }

    // MARK: - Visa / Travel

    private var hasVisaInfo: Bool {
        !document.visaType.isEmpty || !document.destinationCountry.isEmpty
    }

    private var visaTravelSection: some View {
        VStack(spacing: 8) {
            if !document.visaType.isEmpty {
                LabeledContent("Visa Type", value: document.visaType)
            }

            if !document.destinationCountry.isEmpty {
                LabeledContent("Destination Country", value: document.destinationCountry)
            }
        }
    }

    // MARK: - Application

    private var applicationSection: some View {
        VStack(spacing: 8) {
            LabeledContent("Status") {
                HStack(spacing: 4) {
                    Image(systemName: document.applicationStatus.icon)
                        .foregroundStyle(colorForApplicationStatus)
                    Text(document.applicationStatus.rawValue)
                }
            }

            if !document.applicationURL.isEmpty {
                LabeledContent("Application URL", value: document.applicationURL)
            }

            if !document.processingTime.isEmpty {
                LabeledContent("Processing Time", value: document.processingTime)
            }

            if let formattedCost = document.formattedCost {
                LabeledContent("Cost", value: formattedCost)
            }
        }
    }

    // MARK: - Required Documents

    private var requiredDocumentsSection: some View {
        ForEach(document.documentsNeededList, id: \.self) { item in
            Label(item, systemImage: "doc.text")
        }
    }

    // MARK: - Helpers

    private var colorForStatus: Color {
        switch document.statusColor {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .secondary
        }
    }

    private var colorForApplicationStatus: Color {
        switch document.applicationStatus.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .secondary
        }
    }
}
