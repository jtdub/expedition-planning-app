import SwiftUI
import UniformTypeIdentifiers

/// View for importing CSV data into an expedition.
/// Follows the GPXImportView pattern: pick file -> preview -> import.
struct CSVImportView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Bindable var expedition: Expedition

    @State private var viewModel = CSVImportViewModel()
    @State private var showingFilePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if let result = viewModel.importResult {
                    resultView(result: result)
                } else if viewModel.parseResult != nil {
                    previewView
                } else {
                    pickFileView
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if viewModel.parseResult != nil && viewModel.importResult == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            viewModel.performImport(to: expedition)
                        }
                        .disabled(viewModel.effectiveType == nil || viewModel.isImporting)
                    }
                }

                if viewModel.importResult != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, UTType(filenameExtension: "csv") ?? .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    // MARK: - Pick File View

    private var pickFileView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tablecells.badge.ellipsis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Import CSV File")
                    .font(.title2)
                    .fontWeight(.semibold)

                // swiftlint:disable:next line_length
                Text("Select a CSV file to import data into your expedition. Supported types: gear, participants, contacts, itinerary, budget, permits, and resupply points.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingFilePicker = true
            } label: {
                Label("Choose File", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 48)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }

    // MARK: - Preview View

    private var previewView: some View {
        List {
            // Type Detection Section
            Section("Data Type") {
                if let detected = viewModel.detectedType {
                    LabeledContent("Detected") {
                        Label(detected.rawValue, systemImage: detected.icon)
                    }
                } else {
                    Text("Could not auto-detect data type")
                        .foregroundStyle(.orange)
                }

                Picker("Import As", selection: typeBinding) {
                    ForEach(CSVImportService.CSVImportType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type as CSVImportService.CSVImportType?)
                    }
                }
            }

            // Summary Section
            if let result = viewModel.parseResult {
                Section("File Summary") {
                    LabeledContent("Columns", value: "\(result.headers.count)")
                    LabeledContent("Rows", value: "\(result.rows.count)")
                }
            }

            // Duplicate Warnings
            if !viewModel.duplicateNames.isEmpty {
                Section {
                    ForEach(viewModel.duplicateNames, id: \.self) { name in
                        Label(name, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Potential Duplicates")
                } footer: {
                    Text("These items already exist in the expedition. They will be imported as new entries.")
                }
            }

            // Data Preview
            if let result = viewModel.parseResult {
                Section {
                    // Headers
                    ScrollView(.horizontal) {
                        HStack(spacing: 16) {
                            ForEach(result.headers, id: \.self) { header in
                                Text(header)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 80, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Preview rows
                    ForEach(Array(viewModel.previewRows.enumerated()), id: \.offset) { _, row in
                        ScrollView(.horizontal) {
                            HStack(spacing: 16) {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                    Text(cell.isEmpty ? "-" : cell)
                                        .font(.caption)
                                        .foregroundStyle(cell.isEmpty ? .tertiary : .primary)
                                        .frame(minWidth: 80, alignment: .leading)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                } header: {
                    HStack {
                        Text("Preview")
                        Spacer()
                        if let result = viewModel.parseResult, result.rows.count > 20 {
                            Text("Showing first 20 of \(result.rows.count) rows")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkDuplicates(in: expedition)
        }
        .onChange(of: viewModel.selectedType) {
            viewModel.checkDuplicates(in: expedition)
        }
    }

    // MARK: - Result View

    private func resultView(result: CSVImportService.CSVImportResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: result.errorCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(result.errorCount == 0 ? .green : .orange)

            VStack(spacing: 8) {
                Text("Import Complete")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(result.importedCount) items imported")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if result.errorCount > 0 {
                    Text("\(result.errorCount) rows had errors")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
            }

            if !result.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Errors:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(result.errors, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var typeBinding: Binding<CSVImportService.CSVImportType?> {
        Binding(
            get: { viewModel.effectiveType },
            set: { viewModel.selectedType = $0 }
        )
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                viewModel.errorMessage = "No file selected"
                return
            }

            guard url.startAccessingSecurityScopedResource() else {
                viewModel.errorMessage = "Cannot access file"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }
            viewModel.parseFile(url: url)

        case .failure(let error):
            viewModel.errorMessage = "Error selecting file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    CSVImportView(expedition: Expedition(name: "Test Expedition"))
        .modelContainer(for: Expedition.self, inMemory: true)
}
