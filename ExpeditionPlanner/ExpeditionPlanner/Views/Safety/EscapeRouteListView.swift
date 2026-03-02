import SwiftUI
import SwiftData

struct EscapeRouteListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: EscapeRouteViewModel?
    @State private var showingAddSheet = false
    @State private var selectedRoute: EscapeRoute?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                routeList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Escape Routes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.routes.isEmpty {
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
                    viewModel?.loadRoutes(for: expedition)
                }
            ),
            prompt: "Search routes"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    EscapeRouteFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedRoute) { route in
            if let viewModel = viewModel {
                NavigationStack {
                    EscapeRouteDetailView(
                        route: route,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = EscapeRouteViewModel(modelContext: modelContext)
            }
            viewModel?.loadRoutes(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func routeList(viewModel: EscapeRouteViewModel) -> some View {
        if viewModel.routes.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Escape Routes", systemImage: "arrow.uturn.backward.circle")
            } description: {
                Text("Add escape routes to plan bailout options for each expedition segment.")
            } actions: {
                Button("Add Escape Route") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.routes.isEmpty {
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

                // Grouped by route type
                ForEach(viewModel.groupedByType, id: \.routeType) { group in
                    Section {
                        ForEach(group.routes) { route in
                            EscapeRouteRowView(route: route)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRoute = route
                                }
                        }
                        .onDelete { indexSet in
                            deleteRoutes(at: indexSet, from: group.routes, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.routeType.icon)
                            Text(group.routeType.rawValue)
                            Text("(\(group.routes.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: EscapeRouteViewModel) -> some View {
        HStack(spacing: 16) {
            EscapeRouteStatBadge(
                value: "\(viewModel.routes.count)",
                label: "Total",
                icon: "arrow.uturn.backward.circle",
                color: .blue
            )
            EscapeRouteStatBadge(
                value: "\(viewModel.primaryRoutes.count)",
                label: "Primary",
                icon: "arrow.uturn.backward.circle.fill",
                color: .green
            )
            EscapeRouteStatBadge(
                value: "\(viewModel.unverifiedCount)",
                label: "Unverified",
                icon: "questionmark.circle",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: EscapeRouteViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadRoutes(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: EscapeRouteViewModel) -> String {
        var parts: [String] = []
        if let routeType = viewModel.filterRouteType {
            parts.append(routeType.rawValue)
        }
        if viewModel.showUnverifiedOnly {
            parts.append("Unverified")
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " - ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: EscapeRouteViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadRoutes(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Route type filter
            Menu("Route Type") {
                Button {
                    viewModel.filterRouteType = nil
                    viewModel.loadRoutes(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterRouteType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(EscapeRouteType.allCases, id: \.self) { routeType in
                    Button {
                        viewModel.filterRouteType = routeType
                        viewModel.loadRoutes(for: expedition)
                    } label: {
                        Label {
                            Text(routeType.rawValue)
                        } icon: {
                            if viewModel.filterRouteType == routeType {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: routeType.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Unverified toggle
            Toggle("Unverified Only", isOn: Binding(
                get: { viewModel.showUnverifiedOnly },
                set: { newValue in
                    viewModel.showUnverifiedOnly = newValue
                    viewModel.loadRoutes(for: expedition)
                }
            ))

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(EscapeRouteSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadRoutes(for: expedition)
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

    private func deleteRoutes(
        at indexSet: IndexSet,
        from routes: [EscapeRoute],
        viewModel: EscapeRouteViewModel
    ) {
        for index in indexSet {
            viewModel.deleteRoute(routes[index], from: expedition)
        }
    }
}

// MARK: - Stat Badge

struct EscapeRouteStatBadge: View {
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
