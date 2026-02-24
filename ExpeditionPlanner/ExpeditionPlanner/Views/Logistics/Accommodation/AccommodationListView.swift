import SwiftUI
import SwiftData

struct AccommodationListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: AccommodationViewModel?
    @State private var showingAddSheet = false
    @State private var selectedAccommodation: Accommodation?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                accommodationList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Accommodations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.accommodations.isEmpty {
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
                    viewModel?.loadAccommodations(for: expedition)
                }
            ),
            prompt: "Search accommodations"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    AccommodationFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedAccommodation) { accommodation in
            if let viewModel = viewModel {
                NavigationStack {
                    AccommodationDetailView(
                        accommodation: accommodation,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AccommodationViewModel(modelContext: modelContext)
            }
            viewModel?.loadAccommodations(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func accommodationList(viewModel: AccommodationViewModel) -> some View {
        if viewModel.accommodations.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Accommodations", systemImage: "building.2")
            } description: {
                Text("Add hotels, lodges, and other accommodations for your expedition.")
            } actions: {
                Button("Add Accommodation") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.accommodations.isEmpty {
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

                // Current accommodation
                if let current = viewModel.currentAccommodation {
                    Section {
                        AccommodationRowView(accommodation: current)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAccommodation = current
                            }
                    } header: {
                        Label("Current", systemImage: "location.fill")
                    }
                }

                // Grouped by city
                ForEach(viewModel.groupedByCity, id: \.city) { group in
                    let filtered = group.accommodations.filter { $0.id != viewModel.currentAccommodation?.id }
                    if !filtered.isEmpty {
                        Section {
                            ForEach(filtered) { accommodation in
                                AccommodationRowView(accommodation: accommodation)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedAccommodation = accommodation
                                    }
                            }
                            .onDelete { indexSet in
                                deleteAccommodations(at: indexSet, from: filtered, viewModel: viewModel)
                            }
                        } header: {
                            Text(group.city)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: AccommodationViewModel) -> some View {
        HStack(spacing: 16) {
            AccommodationStatBadge(
                value: "\(viewModel.accommodations.count)",
                label: "Total",
                icon: "building.2",
                color: .blue
            )
            AccommodationStatBadge(
                value: "\(viewModel.totalNights)",
                label: "Nights",
                icon: "moon.stars",
                color: .purple
            )
            AccommodationStatBadge(
                value: "\(viewModel.confirmedCount)",
                label: "Confirmed",
                icon: "checkmark.circle",
                color: .green
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: AccommodationViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text("Filtered")
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadAccommodations(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: AccommodationViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadAccommodations(for: expedition)
            } label: {
                Label("Clear Filters", systemImage: viewModel.hasActiveFilters ? "" : "checkmark")
            }

            Divider()

            Menu("Type") {
                Button {
                    viewModel.filterType = nil
                    viewModel.loadAccommodations(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(AccommodationType.allCases, id: \.self) { type in
                    Button {
                        viewModel.filterType = type
                        viewModel.loadAccommodations(for: expedition)
                    } label: {
                        Label(type.rawValue, systemImage: viewModel.filterType == type ? "checkmark" : type.icon)
                    }
                }
            }

            Menu("Status") {
                Button {
                    viewModel.filterStatus = nil
                    viewModel.loadAccommodations(for: expedition)
                } label: {
                    Label("All Statuses", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(AccommodationStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.filterStatus = status
                        viewModel.loadAccommodations(for: expedition)
                    } label: {
                        Label(status.rawValue, systemImage: viewModel.filterStatus == status ? "checkmark" : "")
                    }
                }
            }

            Divider()

            Toggle("Upcoming Only", isOn: Binding(
                get: { viewModel.showUpcomingOnly },
                set: { newValue in
                    viewModel.showUpcomingOnly = newValue
                    viewModel.loadAccommodations(for: expedition)
                }
            ))

            Divider()

            Menu("Sort By") {
                ForEach(AccommodationSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadAccommodations(for: expedition)
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

    private func deleteAccommodations(
        at indexSet: IndexSet,
        from accommodations: [Accommodation],
        viewModel: AccommodationViewModel
    ) {
        for index in indexSet {
            viewModel.deleteAccommodation(accommodations[index], from: expedition)
        }
    }
}

// MARK: - Accommodation Stat Badge

struct AccommodationStatBadge: View {
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

// MARK: - Accommodation Row View

struct AccommodationRowView: View {
    let accommodation: Accommodation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: accommodation.accommodationType.icon)
                .font(.title2)
                .foregroundStyle(typeColor)
                .frame(width: 40, height: 40)
                .background(typeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(accommodation.name)
                    .font(.headline)
                    .lineLimit(1)

                if !accommodation.city.isEmpty {
                    Text(accommodation.city)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if accommodation.checkInDate != nil {
                    Text(accommodation.dateRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(accommodation.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                if accommodation.numberOfNights > 0 {
                    Text("\(accommodation.numberOfNights) nights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch accommodation.accommodationType.color {
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "green": return .green
        case "orange": return .orange
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch accommodation.status.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        AccommodationListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, Accommodation.self], inMemory: true)
}
