import SwiftUI
import SwiftData

struct WaterSourceListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: WaterSourceViewModel?
    @State private var showingAddSheet = false
    @State private var selectedSource: WaterSource?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                sourceList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Water Sources")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.sources.isEmpty {
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
                    viewModel?.loadSources(for: expedition)
                }
            ),
            prompt: "Search sources"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    WaterSourceFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedSource) { source in
            if let viewModel = viewModel {
                NavigationStack {
                    WaterSourceDetailView(
                        source: source,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WaterSourceViewModel(modelContext: modelContext)
            }
            viewModel?.loadSources(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func sourceList(viewModel: WaterSourceViewModel) -> some View {
        if viewModel.sources.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Water Sources", systemImage: "drop.fill")
            } description: {
                Text("Add water sources along your route to plan hydration and treatment needs.")
            } actions: {
                Button("Add Water Source") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.sources.isEmpty {
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

                // Grouped by source type
                ForEach(viewModel.groupedByType, id: \.sourceType) { group in
                    Section {
                        ForEach(group.sources) { source in
                            WaterSourceRowView(source: source)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSource = source
                                }
                        }
                        .onDelete { indexSet in
                            deleteSources(at: indexSet, from: group.sources, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.sourceType.icon)
                            Text(group.sourceType.rawValue)
                            Text("(\(group.sources.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: WaterSourceViewModel) -> some View {
        HStack(spacing: 16) {
            WaterSourceStatBadge(
                value: "\(viewModel.sources.count)",
                label: "Total",
                icon: "drop.fill",
                color: .blue
            )
            WaterSourceStatBadge(
                value: "\(viewModel.verifiedCount)",
                label: "Verified",
                icon: "checkmark.seal.fill",
                color: .green
            )
            WaterSourceStatBadge(
                value: "\(viewModel.needsTreatmentCount)",
                label: "Treatment",
                icon: "line.3.horizontal.decrease",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: WaterSourceViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadSources(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: WaterSourceViewModel) -> String {
        var parts: [String] = []
        if let sourceType = viewModel.filterSourceType {
            parts.append(sourceType.rawValue)
        }
        if let reliability = viewModel.filterReliability {
            parts.append(reliability.rawValue)
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " - ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: WaterSourceViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadSources(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Source type filter
            Menu("Source Type") {
                Button {
                    viewModel.filterSourceType = nil
                    viewModel.loadSources(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterSourceType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(WaterSourceType.allCases, id: \.self) { sourceType in
                    Button {
                        viewModel.filterSourceType = sourceType
                        viewModel.loadSources(for: expedition)
                    } label: {
                        Label {
                            Text(sourceType.rawValue)
                        } icon: {
                            if viewModel.filterSourceType == sourceType {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: sourceType.icon)
                            }
                        }
                    }
                }
            }

            // Reliability filter
            Menu("Reliability") {
                Button {
                    viewModel.filterReliability = nil
                    viewModel.loadSources(for: expedition)
                } label: {
                    Label("All Ratings", systemImage: viewModel.filterReliability == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ReliabilityRating.allCases, id: \.self) { rating in
                    Button {
                        viewModel.filterReliability = rating
                        viewModel.loadSources(for: expedition)
                    } label: {
                        Label {
                            Text(rating.rawValue)
                        } icon: {
                            if viewModel.filterReliability == rating {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: rating.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(WaterSourceSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadSources(for: expedition)
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

    private func deleteSources(
        at indexSet: IndexSet,
        from sources: [WaterSource],
        viewModel: WaterSourceViewModel
    ) {
        for index in indexSet {
            viewModel.deleteSource(sources[index], from: expedition)
        }
    }
}

// MARK: - Stat Badge

struct WaterSourceStatBadge: View {
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
