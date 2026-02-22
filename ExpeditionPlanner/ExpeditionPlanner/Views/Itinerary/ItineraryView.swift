import SwiftUI
import SwiftData

struct ItineraryView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @AppStorage("elevationUnit")
    private var elevationUnit: ElevationUnit = .meters

    @State private var viewModel: ItineraryViewModel?
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false
    @State private var selectedDay: ItineraryDay?
    @State private var isEditMode = false

    var body: some View {
        Group {
            if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel?.totalDays ?? 0 > 0 {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "Done" : "Edit")
                    }
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel, viewModel.totalDays > 0 {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            DayFormView(mode: .create(expedition: expedition), modelContext: modelContext)
        }
        .sheet(item: $selectedDay) { day in
            DayDetailView(day: day, elevationUnit: elevationUnit)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ItineraryViewModel(expedition: expedition, modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: ItineraryViewModel) -> some View {
        if viewModel.totalDays == 0 {
            emptyState
        } else {
            listContent(viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Itinerary Days", systemImage: "calendar.day.timeline.left")
        } description: {
            Text("Add days to plan your expedition's daily schedule.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Day", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func listContent(viewModel: ItineraryViewModel) -> some View {
        List {
            // Elevation Chart Section
            if viewModel.showChartSection {
                Section {
                    ElevationChartView(
                        data: viewModel.elevationChartData,
                        unit: elevationUnit
                    )
                    .frame(height: 200)
                } header: {
                    HStack {
                        Text("Elevation Profile")
                        Spacer()
                        if viewModel.warningCount > 0 {
                            Label("\(viewModel.warningCount)", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            // Summary Section
            Section("Summary") {
                summaryContent(viewModel: viewModel)
            }

            // Days Section
            Section {
                ForEach(viewModel.filteredDays) { day in
                    ItineraryDayRowView(day: day, elevationUnit: elevationUnit)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditMode {
                                selectedDay = day
                            }
                        }
                }
                .onDelete { offsets in
                    viewModel.deleteDays(at: offsets)
                }
                .onMove { source, destination in
                    viewModel.moveDays(from: source, to: destination)
                }
            } header: {
                if let filter = viewModel.filterActivityType {
                    HStack {
                        Text("Days - \(filter.rawValue)")
                        Spacer()
                        Button("Clear") {
                            viewModel.clearFilter()
                        }
                        .font(.caption)
                    }
                } else {
                    Text("Days")
                }
            }
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
    }

    @ViewBuilder
    private func summaryContent(viewModel: ItineraryViewModel) -> some View {
        let summary = viewModel.elevationSummary

        LabeledContent("Total Days") {
            Text("\(viewModel.totalDays)")
        }

        if summary.totalGain > 0 {
            LabeledContent("Total Elevation Gain") {
                Text(ElevationService.formatElevation(summary.totalGain, unit: elevationUnit))
            }
        }

        if summary.totalLoss > 0 {
            LabeledContent("Total Elevation Loss") {
                Text(ElevationService.formatElevation(summary.totalLoss, unit: elevationUnit))
            }
        }

        if let highest = summary.highestPoint {
            LabeledContent("Highest Point") {
                Text(ElevationService.formatElevation(highest, unit: elevationUnit))
            }
        }

        if viewModel.highRiskCount > 0 {
            LabeledContent("High Risk Days") {
                HStack {
                    Text("\(viewModel.highRiskCount)")
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }

        if let distance = viewModel.totalDistance {
            LabeledContent("Total Distance") {
                Text(distance.formatted(as: .kilometers))
            }
        }
    }

    @ViewBuilder
    private func filterMenu(viewModel: ItineraryViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilter()
            } label: {
                Label("All Activities", systemImage: viewModel.filterActivityType == nil ? "checkmark" : "")
            }

            Divider()

            ForEach(ActivityType.allCases, id: \.self) { type in
                let count = viewModel.activityTypeCounts[type] ?? 0
                if count > 0 {
                    Button {
                        viewModel.setFilter(type)
                    } label: {
                        Label {
                            Text("\(type.rawValue) (\(count))")
                        } icon: {
                            if viewModel.filterActivityType == type {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: type.icon)
                            }
                        }
                    }
                }
            }
        } label: {
            let icon = viewModel.filterActivityType == nil
                ? "line.3.horizontal.decrease.circle"
                : "line.3.horizontal.decrease.circle.fill"
            Image(systemName: icon)
        }
    }
}

#Preview {
    NavigationStack {
        ItineraryView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: Expedition.self, inMemory: true)
}
