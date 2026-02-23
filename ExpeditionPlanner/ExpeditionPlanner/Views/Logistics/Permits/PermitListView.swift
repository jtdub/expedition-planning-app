import SwiftUI
import SwiftData

struct PermitListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @State private var viewModel: PermitViewModel?
    @State private var showingAddSheet = false
    @State private var selectedPermit: Permit?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                permitList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Permits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.permits.isEmpty {
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
                    viewModel?.loadPermits(for: expedition)
                }
            ),
            prompt: "Search permits"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    PermitFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedPermit) { permit in
            if let viewModel = viewModel {
                NavigationStack {
                    PermitDetailView(
                        permit: permit,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PermitViewModel(modelContext: modelContext)
            }
            viewModel?.loadPermits(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func permitList(viewModel: PermitViewModel) -> some View {
        if viewModel.permits.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Permits", systemImage: "doc.text")
            } description: {
                Text("Add permits to track required documentation for your expedition.")
            } actions: {
                Button("Add Permit") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.permits.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryRow(viewModel: viewModel)
                }

                // Overdue/Upcoming deadlines
                if !viewModel.overduePermits.isEmpty {
                    Section {
                        ForEach(viewModel.overduePermits) { permit in
                            PermitRowView(permit: permit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPermit = permit
                                }
                        }
                    } header: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if !viewModel.upcomingDeadlines.isEmpty && viewModel.filterStatus == nil {
                    Section {
                        ForEach(viewModel.upcomingDeadlines) { permit in
                            PermitRowView(permit: permit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPermit = permit
                                }
                        }
                    } header: {
                        Label("Upcoming Deadlines", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.orange)
                    }
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped by status
                ForEach(viewModel.groupedByStatus, id: \.status) { group in
                    Section {
                        ForEach(group.permits) { permit in
                            PermitRowView(permit: permit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPermit = permit
                                }
                        }
                        .onDelete { indexSet in
                            deletePermits(at: indexSet, from: group.permits, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.status.icon)
                            Text(group.status.rawValue)
                            Text("(\(group.permits.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Row

    private func summaryRow(viewModel: PermitViewModel) -> some View {
        HStack(spacing: 16) {
            StatBadge(
                value: "\(viewModel.permits.count)",
                label: "Total",
                icon: "doc.text",
                color: .blue
            )
            StatBadge(
                value: "\(viewModel.completedCount)",
                label: "Complete",
                icon: "checkmark.seal.fill",
                color: .green
            )
            StatBadge(
                value: "\(viewModel.pendingCount)",
                label: "Pending",
                icon: "clock",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: PermitViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadPermits(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: PermitViewModel) -> String {
        var parts: [String] = []
        if let status = viewModel.filterStatus {
            parts.append(status.rawValue)
        }
        if let type = viewModel.filterType {
            parts.append(type.rawValue)
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: PermitViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadPermits(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Status filter
            Menu("Status") {
                Button {
                    viewModel.filterStatus = nil
                    viewModel.loadPermits(for: expedition)
                } label: {
                    Label("All Statuses", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(PermitStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.filterStatus = status
                        viewModel.loadPermits(for: expedition)
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

            // Type filter
            Menu("Type") {
                Button {
                    viewModel.filterType = nil
                    viewModel.loadPermits(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(PermitType.allCases, id: \.self) { type in
                    Button {
                        viewModel.filterType = type
                        viewModel.loadPermits(for: expedition)
                    } label: {
                        Label {
                            Text(type.rawValue)
                        } icon: {
                            if viewModel.filterType == type {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: type.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(PermitSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadPermits(for: expedition)
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

    private func deletePermits(
        at indexSet: IndexSet,
        from permits: [Permit],
        viewModel: PermitViewModel
    ) {
        for index in indexSet {
            viewModel.deletePermit(permits[index], from: expedition)
        }
    }
}

#Preview {
    NavigationStack {
        PermitListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, Permit.self], inMemory: true)
}
