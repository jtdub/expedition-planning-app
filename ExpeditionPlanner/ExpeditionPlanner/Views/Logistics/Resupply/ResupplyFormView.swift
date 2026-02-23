import SwiftUI
import SwiftData

enum ResupplyFormMode {
    case create
    case edit(ResupplyPoint)
}

struct ResupplyFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: ResupplyFormMode
    let expedition: Expedition
    var viewModel: ResupplyViewModel

    // Basic info
    @State private var name = ""
    @State private var resupplyDescription = ""
    @State private var dayNumber: Int?
    @State private var hasArrivalDate = false
    @State private var expectedArrivalDate: Date = Date()

    // Location
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var elevationString = ""

    // Post office
    @State private var hasPostOffice = false
    @State private var postOfficeAddress = ""
    @State private var postOfficeHours = ""
    @State private var postOfficePhone = ""
    @State private var mailingInstructions = ""

    // Services
    @State private var hasGroceries = false
    @State private var hasFuel = false
    @State private var hasLodging = false
    @State private var hasRestaurant = false
    @State private var hasShowers = false
    @State private var hasLaundry = false
    @State private var servicesNotes = ""

    // Notes
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingPoint: ResupplyPoint? {
        if case .edit(let point) = mode { return point }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Name", text: $name)
                TextField("Description", text: $resupplyDescription, axis: .vertical)
                    .lineLimit(2...4)

                Stepper(
                    "Day Number: \(dayNumber.map { String($0) } ?? "Not set")",
                    value: Binding(
                        get: { dayNumber ?? 1 },
                        set: { dayNumber = $0 }
                    ),
                    in: 1...365
                )

                Toggle("Expected Arrival Date", isOn: $hasArrivalDate)
                if hasArrivalDate {
                    DatePicker("Date", selection: $expectedArrivalDate, displayedComponents: .date)
                }
            } header: {
                Text("Basic Information")
            }

            // Location
            Section {
                TextField("Latitude", text: $latitudeString)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $longitudeString)
                    .keyboardType(.decimalPad)
                TextField("Elevation (m)", text: $elevationString)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Location")
            } footer: {
                Text("Enter coordinates for map display.")
            }

            // Post Office
            Section {
                Toggle("Has Post Office", isOn: $hasPostOffice)

                if hasPostOffice {
                    TextField("Address", text: $postOfficeAddress, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Hours", text: $postOfficeHours)
                    TextField("Phone", text: $postOfficePhone)
                        .keyboardType(.phonePad)
                    TextField("Mailing Instructions", text: $mailingInstructions, axis: .vertical)
                        .lineLimit(3...6)
                }
            } header: {
                Text("Post Office")
            }

            // Services
            Section {
                Toggle("Groceries", isOn: $hasGroceries)
                Toggle("Fuel", isOn: $hasFuel)
                Toggle("Lodging", isOn: $hasLodging)
                Toggle("Restaurant", isOn: $hasRestaurant)
                Toggle("Showers", isOn: $hasShowers)
                Toggle("Laundry", isOn: $hasLaundry)

                TextField("Services Notes", text: $servicesNotes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Available Services")
            }

            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(isEditing ? "Edit Resupply Point" : "Add Resupply Point")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveResupplyPoint()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let point = editingPoint {
                loadResupplyPoint(point)
            }
        }
    }

    // MARK: - Load/Save

    private func loadResupplyPoint(_ point: ResupplyPoint) {
        name = point.name
        resupplyDescription = point.resupplyDescription
        dayNumber = point.dayNumber
        if let date = point.expectedArrivalDate {
            expectedArrivalDate = date
            hasArrivalDate = true
        }
        if let lat = point.latitude {
            latitudeString = String(format: "%.6f", lat)
        }
        if let lon = point.longitude {
            longitudeString = String(format: "%.6f", lon)
        }
        if let elev = point.elevationMeters {
            elevationString = String(format: "%.0f", elev)
        }
        hasPostOffice = point.hasPostOffice
        postOfficeAddress = point.postOfficeAddress ?? ""
        postOfficeHours = point.postOfficeHours ?? ""
        postOfficePhone = point.postOfficePhone ?? ""
        mailingInstructions = point.mailingInstructions ?? ""
        hasGroceries = point.hasGroceries
        hasFuel = point.hasFuel
        hasLodging = point.hasLodging
        hasRestaurant = point.hasRestaurant
        hasShowers = point.hasShowers
        hasLaundry = point.hasLaundry
        servicesNotes = point.servicesNotes
        notes = point.notes
    }

    private func saveResupplyPoint() {
        let point: ResupplyPoint
        if let existing = editingPoint {
            point = existing
        } else {
            point = ResupplyPoint()
        }

        point.name = name
        point.resupplyDescription = resupplyDescription
        point.dayNumber = dayNumber
        point.expectedArrivalDate = hasArrivalDate ? expectedArrivalDate : nil
        point.latitude = Double(latitudeString)
        point.longitude = Double(longitudeString)
        point.elevationMeters = Double(elevationString)
        point.hasPostOffice = hasPostOffice
        point.postOfficeAddress = postOfficeAddress.isEmpty ? nil : postOfficeAddress
        point.postOfficeHours = postOfficeHours.isEmpty ? nil : postOfficeHours
        point.postOfficePhone = postOfficePhone.isEmpty ? nil : postOfficePhone
        point.mailingInstructions = mailingInstructions.isEmpty ? nil : mailingInstructions
        point.hasGroceries = hasGroceries
        point.hasFuel = hasFuel
        point.hasLodging = hasLodging
        point.hasRestaurant = hasRestaurant
        point.hasShowers = hasShowers
        point.hasLaundry = hasLaundry
        point.servicesNotes = servicesNotes
        point.notes = notes

        if isEditing {
            viewModel.updateResupplyPoint(point, in: expedition)
        } else {
            viewModel.addResupplyPoint(point, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ResupplyFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ResupplyViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
