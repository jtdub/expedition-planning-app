import SwiftUI
import SwiftData
import MapKit

struct ResupplyDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let resupplyPoint: ResupplyPoint
    let expedition: Expedition
    var viewModel: ResupplyViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Schedule
            if resupplyPoint.dayNumber != nil || resupplyPoint.expectedArrivalDate != nil {
                Section {
                    if let day = resupplyPoint.dayNumber {
                        LabeledContent("Day Number", value: "Day \(day)")
                    }
                    if let date = resupplyPoint.expectedArrivalDate {
                        LabeledContent("Expected Arrival") {
                            Text(date.formatted(date: .long, time: .omitted))
                        }
                    }
                } header: {
                    Text("Schedule")
                }
            }

            // Location
            if resupplyPoint.coordinate != nil {
                Section {
                    if let coord = resupplyPoint.coordinate {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        ))) {
                            Marker(resupplyPoint.name, coordinate: coord)
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        LabeledContent("Coordinates") {
                            Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                                .font(.caption)
                        }
                    }

                    if let elev = resupplyPoint.elevation {
                        LabeledContent("Elevation", value: formatElevation(elev))
                    }
                } header: {
                    Text("Location")
                }
            }

            // Post Office
            if resupplyPoint.hasPostOffice {
                Section {
                    Label("Post Office Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    if let address = resupplyPoint.postOfficeAddress {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(address)
                        }
                    }

                    if let phone = resupplyPoint.postOfficePhone {
                        Button {
                            if let url = URL(string: "tel:\(phone)") {
                                openURL(url)
                            }
                        } label: {
                            Label(phone, systemImage: "phone")
                        }
                    }

                    if let hours = resupplyPoint.postOfficeHours {
                        LabeledContent("Hours", value: hours)
                    }

                    if let instructions = resupplyPoint.mailingInstructions {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mailing Instructions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(instructions)
                        }
                    }
                } header: {
                    Label("Post Office", systemImage: "envelope")
                }
            }

            // Services
            if !resupplyPoint.availableServices.isEmpty {
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ServiceBadge(name: "Groceries", icon: "cart.fill", isAvailable: resupplyPoint.hasGroceries)
                        ServiceBadge(name: "Fuel", icon: "fuelpump.fill", isAvailable: resupplyPoint.hasFuel)
                        ServiceBadge(name: "Lodging", icon: "bed.double.fill", isAvailable: resupplyPoint.hasLodging)
                        ServiceBadge(name: "Restaurant", icon: "fork.knife", isAvailable: resupplyPoint.hasRestaurant)
                        ServiceBadge(name: "Showers", icon: "shower.fill", isAvailable: resupplyPoint.hasShowers)
                        ServiceBadge(name: "Laundry", icon: "washer.fill", isAvailable: resupplyPoint.hasLaundry)
                    }
                    .padding(.vertical, 4)

                    if !resupplyPoint.servicesNotes.isEmpty {
                        Text(resupplyPoint.servicesNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Services")
                }
            }

            // Description
            if !resupplyPoint.resupplyDescription.isEmpty {
                Section {
                    Text(resupplyPoint.resupplyDescription)
                } header: {
                    Text("Description")
                }
            }

            // Notes
            if !resupplyPoint.notes.isEmpty {
                Section {
                    Text(resupplyPoint.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Resupply Point", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Resupply Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ResupplyFormView(
                    mode: .edit(resupplyPoint),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Resupply Point?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteResupplyPoint(resupplyPoint, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack {
                if let day = resupplyPoint.dayNumber {
                    Text("Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(day)")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "shippingbox.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.brown)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.brown.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(resupplyPoint.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(resupplyPoint.availableServices.count) services available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatElevation(_ elevation: Measurement<UnitLength>) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        return formatter.string(from: elevation)
    }
}

// MARK: - Service Badge

struct ServiceBadge: View {
    let name: String
    let icon: String
    let isAvailable: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isAvailable ? .green : .secondary)
            Text(name)
                .font(.caption)
                .foregroundStyle(isAvailable ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isAvailable ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ResupplyDetailView(
            resupplyPoint: {
                let point = ResupplyPoint(name: "Bettles, AK")
                point.dayNumber = 7
                point.hasPostOffice = true
                point.postOfficeAddress = "General Delivery, Bettles, AK 99726"
                point.postOfficeHours = "Mon-Fri 9am-5pm"
                point.hasGroceries = true
                point.hasLodging = true
                point.latitude = 66.9178
                point.longitude = -151.5278
                return point
            }(),
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ResupplyViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
