import SwiftUI
import SwiftData
import CoreLocation

enum ShelterFormMode {
    case add
    case edit(Shelter)
}

struct ShelterFormView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: ShelterFormMode
    var viewModel: ShelterViewModel

    @State private var name = ""
    @State private var shelterType: ShelterType = .publicCabin
    @State private var region = ""
    @State private var latitudeString = ""
    @State private var longitudeString = ""
    @State private var elevationString = ""
    @State private var capacityString = ""
    @State private var reservationRequired = false
    @State private var feeString = ""
    @State private var currency = "USD"
    @State private var seasonOpen = ""
    @State private var emergencyUseAllowed = true

    // Amenities
    @State private var hasWoodStove = false
    @State private var hasSleepingPlatform = false
    @State private var hasFirewood = false
    @State private var hasOuthouse = false
    @State private var hasWater = false
    @State private var hasFirstAid = false
    @State private var hasEmergencySupplies = false
    @State private var hasHelipad = false

    @State private var managingAgency = ""
    @State private var contactPhone = ""
    @State private var websiteURL = ""
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingShelter: Shelter? {
        if case .edit(let shelter) = mode { return shelter }
        return nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Shelter Name", text: $name)

                Picker("Type", selection: $shelterType) {
                    ForEach(ShelterType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                TextField("Region", text: $region)
                    .autocorrectionDisabled()
            } header: {
                Text("Basic Information")
            }

            Section {
                TextField("Latitude", text: $latitudeString)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $longitudeString)
                    .keyboardType(.decimalPad)
                TextField("Elevation (meters)", text: $elevationString)
                    .keyboardType(.numberPad)
            } header: {
                Text("Location")
            } footer: {
                Text("Enter coordinates in decimal degrees (e.g., 67.8912, -148.4521)")
            }

            Section {
                TextField("Capacity", text: $capacityString)
                    .keyboardType(.numberPad)
                Toggle("Reservation Required", isOn: $reservationRequired)
                Toggle("Emergency Use Allowed", isOn: $emergencyUseAllowed)
                TextField("Season Open", text: $seasonOpen)
                    .autocorrectionDisabled()

                HStack {
                    TextField("Fee per Night", text: $feeString)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("CAD").tag("CAD")
                        Text("EUR").tag("EUR")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Details")
            }

            Section {
                Toggle("Wood Stove", isOn: $hasWoodStove)
                Toggle("Sleeping Platform", isOn: $hasSleepingPlatform)
                Toggle("Firewood Available", isOn: $hasFirewood)
                Toggle("Outhouse", isOn: $hasOuthouse)
                Toggle("Water Source", isOn: $hasWater)
                Toggle("First Aid Kit", isOn: $hasFirstAid)
                Toggle("Emergency Supplies", isOn: $hasEmergencySupplies)
                Toggle("Helipad", isOn: $hasHelipad)
            } header: {
                Text("Amenities")
            }

            Section {
                TextField("Managing Agency", text: $managingAgency)
                TextField("Contact Phone", text: $contactPhone)
                    .keyboardType(.phonePad)
                TextField("Website URL", text: $websiteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Contact Information")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(isEditing ? "Edit Shelter" : "Add Shelter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveShelter()
                }
                .disabled(name.isEmpty || region.isEmpty)
            }
        }
        .onAppear {
            if let shelter = editingShelter {
                loadShelter(shelter)
            }
        }
    }

    private func loadShelter(_ shelter: Shelter) {
        name = shelter.name
        shelterType = shelter.shelterType
        region = shelter.region
        if let lat = shelter.latitude {
            latitudeString = String(lat)
        }
        if let lon = shelter.longitude {
            longitudeString = String(lon)
        }
        if let elev = shelter.elevationMeters {
            elevationString = String(Int(elev))
        }
        if let cap = shelter.capacity {
            capacityString = String(cap)
        }
        reservationRequired = shelter.reservationRequired
        emergencyUseAllowed = shelter.emergencyUseAllowed
        seasonOpen = shelter.seasonOpen ?? ""
        if let fee = shelter.feePerNight {
            feeString = "\(fee)"
        }
        currency = shelter.feeCurrency

        hasWoodStove = shelter.hasWoodStove
        hasSleepingPlatform = shelter.hasSleepingPlatform
        hasFirewood = shelter.hasFirewood
        hasOuthouse = shelter.hasOuthouse
        hasWater = shelter.hasWater
        hasFirstAid = shelter.hasFirstAid
        hasEmergencySupplies = shelter.hasEmergencySupplies
        hasHelipad = shelter.hasHelipad

        managingAgency = shelter.managingAgency ?? ""
        contactPhone = shelter.contactPhone ?? ""
        websiteURL = shelter.websiteURL ?? ""
        notes = shelter.notes
    }

    private func saveShelter() {
        let shelter: Shelter
        if let existing = editingShelter {
            shelter = existing
        } else {
            shelter = Shelter()
        }

        shelter.name = name
        shelter.shelterType = shelterType
        shelter.region = region
        shelter.latitude = Double(latitudeString)
        shelter.longitude = Double(longitudeString)
        shelter.elevationMeters = Double(elevationString)
        shelter.capacity = Int(capacityString)
        shelter.reservationRequired = reservationRequired
        shelter.emergencyUseAllowed = emergencyUseAllowed
        shelter.seasonOpen = seasonOpen.isEmpty ? nil : seasonOpen
        shelter.feePerNight = Decimal(string: feeString)
        shelter.feeCurrency = currency

        shelter.hasWoodStove = hasWoodStove
        shelter.hasSleepingPlatform = hasSleepingPlatform
        shelter.hasFirewood = hasFirewood
        shelter.hasOuthouse = hasOuthouse
        shelter.hasWater = hasWater
        shelter.hasFirstAid = hasFirstAid
        shelter.hasEmergencySupplies = hasEmergencySupplies
        shelter.hasHelipad = hasHelipad

        shelter.managingAgency = managingAgency.isEmpty ? nil : managingAgency
        shelter.contactPhone = contactPhone.isEmpty ? nil : contactPhone
        shelter.websiteURL = websiteURL.isEmpty ? nil : websiteURL
        shelter.notes = notes

        if isEditing {
            viewModel.updateShelter(shelter)
        } else {
            viewModel.addShelter(shelter)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ShelterFormView(
            mode: .add,
            // swiftlint:disable:next force_try
            viewModel: ShelterViewModel(modelContext: try! ModelContainer(
                for: Shelter.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
