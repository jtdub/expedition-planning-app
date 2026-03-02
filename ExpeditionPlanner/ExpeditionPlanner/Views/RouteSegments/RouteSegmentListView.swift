import SwiftUI
import SwiftData

struct RouteSegmentListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: RouteSegmentViewModel?
    @State private var showingAddSheet = false
    @State private var selectedSegment: RouteSegment?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                segmentList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Route Segments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.segments.isEmpty {
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
                    viewModel?.loadSegments(for: expedition)
                }
            ),
            prompt: "Search segments"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    RouteSegmentFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedSegment) { segment in
            if let viewModel = viewModel {
                NavigationStack {
                    RouteSegmentDetailView(
                        segment: segment,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RouteSegmentViewModel(modelContext: modelContext)
            }
            viewModel?.loadSegments(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func segmentList(viewModel: RouteSegmentViewModel) -> some View {
        if viewModel.segments.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Route Segments", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            } description: {
                Text("Add route segments to break down your expedition route by terrain and difficulty.")
            } actions: {
                Button("Add Route Segment") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.segments.isEmpty {
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

                // Grouped by terrain type
                ForEach(viewModel.groupedByTerrain, id: \.terrainType) { group in
                    Section {
                        ForEach(group.segments) { segment in
                            RouteSegmentRowView(segment: segment)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSegment = segment
                                }
                        }
                        .onDelete { indexSet in
                            deleteSegments(at: indexSet, from: group.segments, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.terrainType.icon)
                            Text(group.terrainType.rawValue)
                            Text("(\(group.segments.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: RouteSegmentViewModel) -> some View {
        HStack(spacing: 16) {
            RouteSegmentStatBadge(
                value: "\(viewModel.segments.count)",
                label: "Segments",
                icon: "point.topleft.down.to.point.bottomright.curvepath",
                color: .blue
            )
            RouteSegmentStatBadge(
                value: formatDistanceKm(viewModel.totalDistance),
                label: "Distance",
                icon: "ruler",
                color: .green
            )
            RouteSegmentStatBadge(
                value: formatElevationM(viewModel.totalElevationGain),
                label: "Elev. Gain",
                icon: "arrow.up.right",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: RouteSegmentViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadSegments(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: RouteSegmentViewModel) -> String {
        var parts: [String] = []
        if let terrain = viewModel.filterTerrainType {
            parts.append(terrain.rawValue)
        }
        if let difficulty = viewModel.filterDifficulty {
            parts.append(difficulty.rawValue)
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " - ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: RouteSegmentViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadSegments(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Terrain type filter
            Menu("Terrain Type") {
                Button {
                    viewModel.filterTerrainType = nil
                    viewModel.loadSegments(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterTerrainType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(TerrainType.allCases, id: \.self) { terrain in
                    Button {
                        viewModel.filterTerrainType = terrain
                        viewModel.loadSegments(for: expedition)
                    } label: {
                        Label {
                            Text(terrain.rawValue)
                        } icon: {
                            if viewModel.filterTerrainType == terrain {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: terrain.icon)
                            }
                        }
                    }
                }
            }

            // Difficulty filter
            Menu("Difficulty") {
                Button {
                    viewModel.filterDifficulty = nil
                    viewModel.loadSegments(for: expedition)
                } label: {
                    Label("All Difficulties", systemImage: viewModel.filterDifficulty == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(DifficultyRating.allCases, id: \.self) { difficulty in
                    Button {
                        viewModel.filterDifficulty = difficulty
                        viewModel.loadSegments(for: expedition)
                    } label: {
                        Label {
                            Text(difficulty.rawValue)
                        } icon: {
                            if viewModel.filterDifficulty == difficulty {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: difficulty.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(RouteSegmentSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadSegments(for: expedition)
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

    private func deleteSegments(
        at indexSet: IndexSet,
        from segments: [RouteSegment],
        viewModel: RouteSegmentViewModel
    ) {
        for index in indexSet {
            viewModel.deleteSegment(segments[index], from: expedition)
        }
    }

    // MARK: - Formatting Helpers

    private func formatDistanceKm(_ meters: Double) -> String {
        let km = meters / 1000.0
        if km < 1 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", km)
    }

    private func formatElevationM(_ meters: Double) -> String {
        return String(format: "%.0f m", meters)
    }
}

// MARK: - Stat Badge

struct RouteSegmentStatBadge: View {
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
