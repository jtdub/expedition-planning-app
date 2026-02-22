import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss)
    private var dismiss

    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var locationName: String

    @State private var region: MKCoordinateRegion
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var cameraPosition: MapCameraPosition

    init(coordinate: Binding<CLLocationCoordinate2D?>, locationName: Binding<String>) {
        self._coordinate = coordinate
        self._locationName = locationName

        let initialCoordinate = coordinate.wrappedValue ?? CLLocationCoordinate2D(
            latitude: 37.7749,
            longitude: -122.4194
        )

        self._region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))

        self._selectedCoordinate = State(initialValue: coordinate.wrappedValue)

        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                Map(position: $cameraPosition, interactionModes: .all) {
                    if let coord = selectedCoordinate {
                        Marker(locationName.isEmpty ? "Selected" : locationName, coordinate: coord)
                            .tint(.red)
                    }
                }
                .onMapCameraChange { context in
                    region = context.region
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }

                // Crosshair for center selection
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.red)
                            .shadow(color: .white, radius: 2)
                        Spacer()
                    }
                    Spacer()
                }

                // Search overlay
                VStack {
                    searchBar
                        .padding()

                    if !searchResults.isEmpty {
                        searchResultsList
                    }

                    Spacer()

                    // Select center button
                    Button {
                        selectCenterLocation()
                    } label: {
                        Label("Select This Location", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        coordinate = selectedCoordinate
                        dismiss()
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search location", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown")
                                .font(.body)
                                .foregroundStyle(.primary)

                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()
                }
            }
        }
        .frame(maxHeight: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            isSearching = false

            if let response {
                searchResults = Array(response.mapItems.prefix(5))
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        locationName = item.name ?? ""
        searchResults = []
        searchText = ""

        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }

    private func selectCenterLocation() {
        // Use the tracked region center
        selectedCoordinate = region.center
    }
}

// MARK: - Coordinate Display Helper

struct CoordinateView: View {
    let coordinate: CLLocationCoordinate2D?

    var body: some View {
        if let coord = coordinate {
            Text(formatCoordinate(coord))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("No coordinates")
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
    }

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        let latDirection = coord.latitude >= 0 ? "N" : "S"
        let lonDirection = coord.longitude >= 0 ? "E" : "W"

        return String(
            format: "%.4f°%@ %.4f°%@",
            abs(coord.latitude),
            latDirection,
            abs(coord.longitude),
            lonDirection
        )
    }
}

#Preview {
    LocationPickerView(
        coordinate: .constant(CLLocationCoordinate2D(latitude: -13.5, longitude: -72.5)),
        locationName: .constant("Cusco")
    )
}
