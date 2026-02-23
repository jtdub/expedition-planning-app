import SwiftUI
import SwiftData

struct ShelterListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @State private var viewModel: ShelterViewModel?
    @State private var showingAddSheet = false
    @State private var selectedShelter: Shelter?
    @State private var filterRegion: String?
    @State private var filterType: ShelterType?
    @State private var searchText = ""

    var body: some View {
        Group {
            if let viewModel = viewModel {
                shelterList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Shelters & Cabins")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search shelters")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Menu("Region") {
                        Button("All Regions") {
                            filterRegion = nil
                        }
                        ForEach(ShelterService.availableRegions, id: \.self) { region in
                            Button(region) {
                                filterRegion = region
                            }
                        }
                    }

                    Menu("Type") {
                        Button("All Types") {
                            filterType = nil
                        }
                        ForEach(ShelterType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                filterType = type
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    ShelterFormView(mode: .add, viewModel: viewModel)
                }
            }
        }
        .sheet(item: $selectedShelter) { shelter in
            if let viewModel = viewModel {
                NavigationStack {
                    ShelterDetailView(shelter: shelter, viewModel: viewModel)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = ShelterViewModel(modelContext: modelContext)
                vm.seedIfNeeded()
                vm.loadAllShelters()
                viewModel = vm
            }
        }
    }

    @ViewBuilder
    private func shelterList(viewModel: ShelterViewModel) -> some View {
        let filteredShelters = viewModel.shelters.filter { shelter in
            let matchesRegion = filterRegion == nil || shelter.region == filterRegion
            let matchesType = filterType == nil || shelter.shelterType == filterType
            let matchesSearch = searchText.isEmpty ||
                shelter.name.localizedCaseInsensitiveContains(searchText) ||
                shelter.region.localizedCaseInsensitiveContains(searchText)
            return matchesRegion && matchesType && matchesSearch
        }

        if filteredShelters.isEmpty {
            ContentUnavailableView {
                Label("No Shelters", systemImage: "house.slash")
            } description: {
                if !searchText.isEmpty {
                    Text("No shelters match your search.")
                } else {
                    Text("Add shelters and cabins to track them on your expeditions.")
                }
            } actions: {
                Button("Add Shelter") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                // Group by region
                let grouped = Dictionary(grouping: filteredShelters) { $0.region }
                let sortedRegions = grouped.keys.sorted()

                ForEach(sortedRegions, id: \.self) { region in
                    Section {
                        ForEach(grouped[region] ?? []) { shelter in
                            ShelterRow(shelter: shelter)
                                .onTapGesture {
                                    selectedShelter = shelter
                                }
                        }
                        .onDelete { indexSet in
                            deleteShelters(at: indexSet, from: grouped[region] ?? [], viewModel: viewModel)
                        }
                    } header: {
                        Text(region)
                    }
                }
            }
        }
    }

    private func deleteShelters(
        at indexSet: IndexSet,
        from shelters: [Shelter],
        viewModel: ShelterViewModel
    ) {
        for index in indexSet {
            viewModel.deleteShelter(shelters[index])
        }
    }
}

// MARK: - Shelter Row

struct ShelterRow: View {
    let shelter: Shelter

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: shelter.shelterType.icon)
                .font(.title2)
                .foregroundStyle(colorForType(shelter.shelterType))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(shelter.name)
                        .font(.headline)
                    if shelter.isUserAdded {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(shelter.shelterType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let capacity = shelter.capacity {
                    Text("\(capacity) ppl")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let elevation = shelter.elevationMeters {
                    Text("\(Int(elevation))m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func colorForType(_ type: ShelterType) -> Color {
        switch type.color {
        case "brown": return .brown
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "gray": return .gray
        case "teal": return .teal
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        ShelterListView()
    }
    .modelContainer(for: Shelter.self, inMemory: true)
}
