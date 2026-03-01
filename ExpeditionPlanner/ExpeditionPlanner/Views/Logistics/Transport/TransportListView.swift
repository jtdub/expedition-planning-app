import SwiftUI
import SwiftData

struct TransportListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: TransportViewModel?
    @State private var showingAddSheet = false
    @State private var selectedLeg: TransportLeg?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                transportList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Transport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.transportLegs.isEmpty {
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
                    viewModel?.loadTransportLegs(for: expedition)
                }
            ),
            prompt: "Search transport"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    TransportFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedLeg) { leg in
            if let viewModel = viewModel {
                NavigationStack {
                    TransportDetailView(
                        transportLeg: leg,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TransportViewModel(modelContext: modelContext)
            }
            viewModel?.loadTransportLegs(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func transportList(viewModel: TransportViewModel) -> some View {
        if viewModel.transportLegs.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Transport", systemImage: "airplane")
            } description: {
                Text("Add flights, shuttles, and other transport for your expedition.")
            } actions: {
                Button("Add Transport") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.transportLegs.isEmpty {
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

                // Grouped by date
                ForEach(viewModel.groupedByDate, id: \.date) { group in
                    Section {
                        ForEach(group.legs) { leg in
                            TransportRowView(leg: leg)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedLeg = leg
                                }
                        }
                        .onDelete { indexSet in
                            deleteLegs(at: indexSet, from: group.legs, viewModel: viewModel)
                        }
                    } header: {
                        if group.date == Date.distantFuture {
                            Text("Date TBD")
                        } else {
                            Text(group.date.formatted(date: .long, time: .omitted))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: TransportViewModel) -> some View {
        HStack(spacing: 16) {
            TransportStatBadge(
                value: "\(viewModel.transportLegs.count)",
                label: "Total",
                icon: "list.bullet",
                color: .blue
            )
            TransportStatBadge(
                value: "\(viewModel.flightLegs.count)",
                label: "Flights",
                icon: "airplane",
                color: .cyan
            )
            TransportStatBadge(
                value: "\(viewModel.upcomingLegs.count)",
                label: "Upcoming",
                icon: "calendar",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: TransportViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text("Filtered")
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadTransportLegs(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: TransportViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadTransportLegs(for: expedition)
            } label: {
                Label("Clear Filters", systemImage: viewModel.hasActiveFilters ? "" : "checkmark")
            }

            Divider()

            Menu("Transport Type") {
                Button {
                    viewModel.filterType = nil
                    viewModel.loadTransportLegs(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(TransportType.allCases, id: \.self) { type in
                    Button {
                        viewModel.filterType = type
                        viewModel.loadTransportLegs(for: expedition)
                    } label: {
                        Label(type.rawValue, systemImage: viewModel.filterType == type ? "checkmark" : type.icon)
                    }
                }
            }

            Divider()

            Toggle("Upcoming Only", isOn: Binding(
                get: { viewModel.showUpcomingOnly },
                set: { newValue in
                    viewModel.showUpcomingOnly = newValue
                    viewModel.loadTransportLegs(for: expedition)
                }
            ))

            Divider()

            Menu("Sort By") {
                ForEach(TransportSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadTransportLegs(for: expedition)
                    } label: {
                        Label(order.rawValue, systemImage: viewModel.sortOrder == order ? "checkmark" : "")
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

    private func deleteLegs(
        at indexSet: IndexSet,
        from legs: [TransportLeg],
        viewModel: TransportViewModel
    ) {
        for index in indexSet {
            viewModel.deleteTransportLeg(legs[index], from: expedition)
        }
    }
}

// MARK: - Transport Stat Badge

struct TransportStatBadge: View {
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

// MARK: - Transport Row View

struct TransportRowView: View {
    let leg: TransportLeg

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: leg.transportType.icon)
                .font(.title2)
                .foregroundStyle(colorForType)
                .frame(width: 40, height: 40)
                .background(colorForType.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(leg.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                Text(leg.routeSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let departure = leg.departureTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(departure.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                        if !leg.formattedDuration.isEmpty && leg.formattedDuration != "N/A" {
                            Text("(\(leg.formattedDuration))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status badge
            Text(leg.status.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var colorForType: Color {
        switch leg.transportType.color {
        case "blue": return .blue
        case "green": return .green
        case "cyan": return .cyan
        case "orange": return .orange
        case "gray": return .secondary
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch leg.status.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        case "gray": return .secondary
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        TransportListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, TransportLeg.self], inMemory: true)
}
