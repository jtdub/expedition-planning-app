import SwiftUI
import SwiftData

struct RiskAssessmentListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: RiskAssessmentViewModel?
    @State private var showingAddSheet = false
    @State private var selectedAssessment: RiskAssessment?
    @State private var showingRiskMatrix = false

    var body: some View {
        Group {
            if let viewModel = viewModel {
                assessmentList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Risk Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.assessments.isEmpty {
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
                    viewModel?.loadAssessments(for: expedition)
                }
            ),
            prompt: "Search risks"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    RiskAssessmentFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedAssessment) { assessment in
            if let viewModel = viewModel {
                NavigationStack {
                    RiskAssessmentDetailView(
                        assessment: assessment,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(isPresented: $showingRiskMatrix) {
            if let viewModel = viewModel {
                NavigationStack {
                    RiskMatrixView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RiskAssessmentViewModel(modelContext: modelContext)
            }
            viewModel?.loadAssessments(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func assessmentList(viewModel: RiskAssessmentViewModel) -> some View {
        if viewModel.assessments.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Risk Assessments", systemImage: "exclamationmark.shield")
            } description: {
                Text("Add risk assessments to identify and mitigate hazards.")
            } actions: {
                Button("Add Risk Assessment") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.assessments.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryView(viewModel: viewModel)
                }

                // Risk Matrix button
                Section {
                    Button {
                        showingRiskMatrix = true
                    } label: {
                        Label("View Risk Matrix", systemImage: "square.grid.3x3")
                    }
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Critical risks first
                if !viewModel.criticalRisks.isEmpty {
                    Section {
                        ForEach(viewModel.criticalRisks) { assessment in
                            RiskAssessmentRowView(assessment: assessment)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAssessment = assessment
                                }
                        }
                    } header: {
                        Label("Critical Risks", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // High risks
                if !viewModel.highRisks.isEmpty {
                    Section {
                        ForEach(viewModel.highRisks) { assessment in
                            RiskAssessmentRowView(assessment: assessment)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAssessment = assessment
                                }
                        }
                    } header: {
                        Label("High Risks", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                // Grouped by hazard type
                ForEach(viewModel.groupedByHazardType, id: \.hazardType) { group in
                    let filteredGroup = group.assessments.filter {
                        $0.riskRating != .critical && $0.riskRating != .high || $0.isAddressed
                    }
                    if !filteredGroup.isEmpty {
                        Section {
                            ForEach(filteredGroup) { assessment in
                                RiskAssessmentRowView(assessment: assessment)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedAssessment = assessment
                                    }
                            }
                            .onDelete { indexSet in
                                deleteAssessments(at: indexSet, from: filteredGroup, viewModel: viewModel)
                            }
                        } header: {
                            HStack {
                                Image(systemName: group.hazardType.icon)
                                Text(group.hazardType.rawValue)
                                Text("(\(filteredGroup.count))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: RiskAssessmentViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                RiskStatBadge(
                    value: "\(viewModel.assessments.count)",
                    label: "Total",
                    icon: "list.bullet.clipboard",
                    color: .blue
                )
                RiskStatBadge(
                    value: "\(viewModel.needsAttentionCount)",
                    label: "Needs Attention",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
                RiskStatBadge(
                    value: "\(viewModel.addressedCount)",
                    label: "Addressed",
                    icon: "checkmark.shield",
                    color: .green
                )
            }

            // Risk rating breakdown
            HStack(spacing: 8) {
                ForEach([RiskRating.critical, .high, .medium, .low], id: \.self) { rating in
                    let count = viewModel.riskRatingCounts[rating] ?? 0
                    if count > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForRating(rating))
                                .frame(width: 8, height: 8)
                            Text("\(count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: RiskAssessmentViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadAssessments(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: RiskAssessmentViewModel) -> String {
        var parts: [String] = []
        if let hazardType = viewModel.filterHazardType {
            parts.append(hazardType.rawValue)
        }
        if let rating = viewModel.filterRiskRating {
            parts.append(rating.label)
        }
        if viewModel.showUnaddressedOnly {
            parts.append("Unaddressed")
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " - ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: RiskAssessmentViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadAssessments(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Hazard type filter
            Menu("Hazard Type") {
                Button {
                    viewModel.filterHazardType = nil
                    viewModel.loadAssessments(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterHazardType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(HazardType.allCases, id: \.self) { hazardType in
                    Button {
                        viewModel.filterHazardType = hazardType
                        viewModel.loadAssessments(for: expedition)
                    } label: {
                        Label {
                            Text(hazardType.rawValue)
                        } icon: {
                            if viewModel.filterHazardType == hazardType {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: hazardType.icon)
                            }
                        }
                    }
                }
            }

            // Risk rating filter
            Menu("Risk Rating") {
                Button {
                    viewModel.filterRiskRating = nil
                    viewModel.loadAssessments(for: expedition)
                } label: {
                    Label("All Ratings", systemImage: viewModel.filterRiskRating == nil ? "checkmark" : "")
                }

                Divider()

                ForEach([RiskRating.critical, .high, .medium, .low], id: \.self) { rating in
                    Button {
                        viewModel.filterRiskRating = rating
                        viewModel.loadAssessments(for: expedition)
                    } label: {
                        Label(
                            rating.label,
                            systemImage: viewModel.filterRiskRating == rating ? "checkmark" : ""
                        )
                    }
                }
            }

            Divider()

            // Unaddressed toggle
            Toggle("Unaddressed Only", isOn: Binding(
                get: { viewModel.showUnaddressedOnly },
                set: { newValue in
                    viewModel.showUnaddressedOnly = newValue
                    viewModel.loadAssessments(for: expedition)
                }
            ))

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(RiskSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadAssessments(for: expedition)
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

    private func deleteAssessments(
        at indexSet: IndexSet,
        from assessments: [RiskAssessment],
        viewModel: RiskAssessmentViewModel
    ) {
        for index in indexSet {
            viewModel.deleteAssessment(assessments[index], from: expedition)
        }
    }

    private func colorForRating(_ rating: RiskRating) -> Color {
        switch rating.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .secondary
        }
    }
}

// MARK: - Risk Stat Badge

struct RiskStatBadge: View {
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

// MARK: - Risk Assessment Row View

struct RiskAssessmentRowView: View {
    let assessment: RiskAssessment

    var body: some View {
        HStack(spacing: 12) {
            // Risk indicator
            VStack {
                Image(systemName: assessment.riskRating.icon)
                    .font(.title2)
                    .foregroundStyle(colorForRating)
            }
            .frame(width: 40, height: 40)
            .background(colorForRating.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(assessment.title)
                        .font(.headline)
                        .lineLimit(1)

                    if assessment.isAddressed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    Label(assessment.hazardType.rawValue, systemImage: assessment.hazardType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let location = assessment.location, !location.isEmpty {
                        Text("- \(location)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Risk score badge
            VStack(spacing: 2) {
                Text("\(assessment.riskScore)")
                    .font(.headline)
                    .foregroundStyle(colorForRating)
                Text("Risk")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var colorForRating: Color {
        switch assessment.riskRating.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        RiskAssessmentListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, RiskAssessment.self], inMemory: true)
}
