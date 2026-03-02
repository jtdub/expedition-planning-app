import SwiftUI
import SwiftData

struct TravelDocumentListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: TravelDocumentViewModel?
    @State private var showingAddSheet = false
    @State private var selectedDocument: TravelDocument?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                documentList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Travel Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.documents.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    viewModel?.loadDocuments(for: expedition)
                }
            ),
            prompt: "Search documents"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    TravelDocumentFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedDocument) { document in
            if let viewModel = viewModel {
                NavigationStack {
                    TravelDocumentDetailView(
                        document: document,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TravelDocumentViewModel(modelContext: modelContext)
            }
            viewModel?.loadDocuments(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func documentList(viewModel: TravelDocumentViewModel) -> some View {
        if viewModel.documents.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Travel Documents", systemImage: "book.closed")
            } description: {
                Text("Track passports, visas, and other travel documents for your expedition.")
            } actions: {
                Button("Add Travel Document") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.documents.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryView(viewModel: viewModel)
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped by document type
                ForEach(viewModel.groupedByType, id: \.documentType) { group in
                    Section {
                        ForEach(group.documents) { document in
                            TravelDocumentRowView(document: document)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDocument = document
                                }
                        }
                        .onDelete { indexSet in
                            deleteDocuments(at: indexSet, from: group.documents, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.documentType.icon)
                            Text(group.documentType.rawValue)
                            Text("(\(group.documents.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: TravelDocumentViewModel) -> some View {
        HStack(spacing: 16) {
            TravelDocumentStatBadge(
                value: "\(viewModel.documents.count)",
                label: "Total",
                icon: "book.closed",
                color: .blue
            )
            TravelDocumentStatBadge(
                value: "\(viewModel.actionRequiredCount)",
                label: "Action",
                icon: "exclamationmark.circle",
                color: .orange
            )
            TravelDocumentStatBadge(
                value: "\(viewModel.expiredCount)",
                label: "Expired",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: TravelDocumentViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadDocuments(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: TravelDocumentViewModel) -> String {
        var parts: [String] = []
        if let docType = viewModel.filterDocumentType {
            parts.append(docType.rawValue)
        }
        if let status = viewModel.filterStatus {
            parts.append(status.rawValue)
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " - ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: TravelDocumentViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadDocuments(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Document type filter
            Menu("Document Type") {
                Button {
                    viewModel.filterDocumentType = nil
                    viewModel.loadDocuments(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterDocumentType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(DocumentType.allCases, id: \.self) { docType in
                    Button {
                        viewModel.filterDocumentType = docType
                        viewModel.loadDocuments(for: expedition)
                    } label: {
                        Label {
                            Text(docType.rawValue)
                        } icon: {
                            if viewModel.filterDocumentType == docType {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: docType.icon)
                            }
                        }
                    }
                }
            }

            // Application status filter
            Menu("Application Status") {
                Button {
                    viewModel.filterStatus = nil
                    viewModel.loadDocuments(for: expedition)
                } label: {
                    Label("All Statuses", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ApplicationStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.filterStatus = status
                        viewModel.loadDocuments(for: expedition)
                    } label: {
                        Label {
                            Text(status.rawValue)
                        } icon: {
                            if viewModel.filterStatus == status {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: status.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(TravelDocumentSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadDocuments(for: expedition)
                    } label: {
                        Label(
                            order.rawValue,
                            systemImage: viewModel.sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Delete

    private func deleteDocuments(
        at indexSet: IndexSet,
        from documents: [TravelDocument],
        viewModel: TravelDocumentViewModel
    ) {
        for index in indexSet {
            viewModel.deleteDocument(documents[index], from: expedition)
        }
    }
}

// MARK: - Stat Badge

struct TravelDocumentStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
