import SwiftUI
import SwiftData
import MapKit

struct ShelterDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let shelter: Shelter
    var viewModel: ShelterViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var mapRegion: MKCoordinateRegion?

    var body: some View {
        List {
            // Map Preview
            if let coordinate = shelter.coordinate {
                Section {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    ))) {
                        Marker(shelter.name, coordinate: coordinate)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .listRowInsets(EdgeInsets())
                }
            }

            // Basic Info
            Section {
                LabeledContent("Type") {
                    Label(shelter.shelterType.rawValue, systemImage: shelter.shelterType.icon)
                }
                LabeledContent("Region", value: shelter.region)

                if shelter.isUserAdded {
                    LabeledContent("Added By") {
                        Label("You", systemImage: "person.fill")
                    }
                }
            } header: {
                Text("Information")
            }

            // Location
            Section {
                if let lat = shelter.latitude, let lon = shelter.longitude {
                    LabeledContent("Coordinates") {
                        Text(String(format: "%.4f, %.4f", lat, lon))
                            .font(.caption)
                    }
                }

                if let elevation = shelter.elevation {
                    LabeledContent("Elevation") {
                        Text(formatElevation(elevation))
                    }
                }
            } header: {
                Text("Location")
            }

            // Capacity & Availability
            Section {
                if let capacity = shelter.capacity {
                    LabeledContent("Capacity", value: "\(capacity) people")
                }

                LabeledContent("Reservation Required") {
                    Image(systemName: shelter.reservationRequired ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(shelter.reservationRequired ? .orange : .green)
                }

                LabeledContent("Emergency Use") {
                    Image(systemName: shelter.emergencyUseAllowed ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(shelter.emergencyUseAllowed ? .green : .red)
                }

                if let season = shelter.seasonOpen, !season.isEmpty {
                    LabeledContent("Season", value: season)
                }

                if let fee = shelter.feeText {
                    LabeledContent("Fee", value: fee)
                }
            } header: {
                Text("Availability")
            }

            // Amenities
            if !shelter.amenities.isEmpty {
                Section {
                    ForEach(shelter.amenities, id: \.self) { amenity in
                        Label(amenity.rawValue, systemImage: amenity.icon)
                    }
                } header: {
                    Text("Amenities")
                }
            }

            // Contact
            if shelter.managingAgency != nil || shelter.contactPhone != nil || shelter.websiteURL != nil {
                Section {
                    if let agency = shelter.managingAgency {
                        LabeledContent("Managing Agency", value: agency)
                    }

                    if let phone = shelter.contactPhone {
                        Button {
                            callPhone(phone)
                        } label: {
                            HStack {
                                Text(phone)
                                Spacer()
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .tint(.primary)
                    }

                    if let urlString = shelter.websiteURL, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Text("Website")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                } header: {
                    Text("Contact")
                }
            }

            // Notes
            if !shelter.notes.isEmpty {
                Section {
                    Text(shelter.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Delete Button (only for user-added)
            if shelter.isUserAdded {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Shelter")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(shelter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ShelterFormView(mode: .edit(shelter), viewModel: viewModel)
            }
        }
        .confirmationDialog(
            "Delete Shelter",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteShelter(shelter)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this shelter? This cannot be undone.")
        }
    }

    private func callPhone(_ number: String) {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func formatElevation(_ elevation: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        return formatter.string(from: elevation)
    }
}

#Preview {
    NavigationStack {
        ShelterDetailView(
            shelter: {
                let shelter = Shelter(
                    name: "Test Cabin",
                    shelterType: .publicCabin,
                    latitude: 67.89,
                    longitude: -148.45,
                    elevationMeters: 1220,
                    region: "Brooks Range",
                    capacity: 6,
                    notes: "Test notes"
                )
                shelter.hasWoodStove = true
                shelter.hasSleepingPlatform = true
                return shelter
            }(),
            // swiftlint:disable:next force_try
            viewModel: ShelterViewModel(modelContext: try! ModelContainer(
                for: Shelter.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
