import SwiftUI
import SwiftData

struct ResupplyListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @State private var viewModel: ResupplyViewModel?
    @State private var showingAddSheet = false
    @State private var selectedPoint: ResupplyPoint?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                resupplyList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Resupply Points")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.resupplyPoints.isEmpty {
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
                    viewModel?.loadResupplyPoints(for: expedition)
                }
            ),
            prompt: "Search resupply points"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    ResupplyFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedPoint) { point in
            if let viewModel = viewModel {
                NavigationStack {
                    ResupplyDetailView(
                        resupplyPoint: point,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ResupplyViewModel(modelContext: modelContext)
            }
            viewModel?.loadResupplyPoints(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func resupplyList(viewModel: ResupplyViewModel) -> some View {
        if viewModel.resupplyPoints.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Resupply Points", systemImage: "shippingbox")
            } description: {
                Text("Add resupply points to track post offices, stores, and services along your route.")
            } actions: {
                Button("Add Resupply Point") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.resupplyPoints.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryRow(viewModel: viewModel)
                }

                // Upcoming resupply
                if !viewModel.upcomingResupply.isEmpty && !viewModel.hasActiveFilters {
                    Section {
                        ForEach(viewModel.upcomingResupply) { point in
                            ResupplyRowView(resupplyPoint: point)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPoint = point
                                }
                        }
                    } header: {
                        Label("Upcoming", systemImage: "calendar.badge.clock")
                            .foregroundStyle(.orange)
                    }
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // All points
                Section {
                    ForEach(viewModel.resupplyPoints) { point in
                        ResupplyRowView(resupplyPoint: point)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPoint = point
                            }
                    }
                    .onDelete { indexSet in
                        deletePoints(at: indexSet, from: viewModel.resupplyPoints, viewModel: viewModel)
                    }
                } header: {
                    Text("All Resupply Points")
                }
            }
        }
    }

    // MARK: - Summary Row

    private func summaryRow(viewModel: ResupplyViewModel) -> some View {
        HStack(spacing: 16) {
            StatBadge(
                value: "\(viewModel.resupplyPoints.count)",
                label: "Total",
                icon: "shippingbox",
                color: .brown
            )
            StatBadge(
                value: "\(viewModel.pointsWithPostOffice.count)",
                label: "Post Office",
                icon: "envelope",
                color: .blue
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: ResupplyViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadResupplyPoints(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: ResupplyViewModel) -> String {
        var parts: [String] = []
        if viewModel.filterHasPostOffice {
            parts.append("Post Office")
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: ResupplyViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadResupplyPoints(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            Button {
                viewModel.filterHasPostOffice.toggle()
                viewModel.loadResupplyPoints(for: expedition)
            } label: {
                Label(
                    "Has Post Office",
                    systemImage: viewModel.filterHasPostOffice ? "checkmark" : ""
                )
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(ResupplySortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadResupplyPoints(for: expedition)
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

    private func deletePoints(
        at indexSet: IndexSet,
        from points: [ResupplyPoint],
        viewModel: ResupplyViewModel
    ) {
        for index in indexSet {
            viewModel.deleteResupplyPoint(points[index], from: expedition)
        }
    }
}

#Preview {
    NavigationStack {
        ResupplyListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, ResupplyPoint.self], inMemory: true)
}
