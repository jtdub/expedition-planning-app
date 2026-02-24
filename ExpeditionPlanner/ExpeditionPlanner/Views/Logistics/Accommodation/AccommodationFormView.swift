import SwiftUI
import SwiftData

enum AccommodationFormMode {
    case create
    case edit(Accommodation)
}

struct AccommodationFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: AccommodationFormMode
    let expedition: Expedition
    var viewModel: AccommodationViewModel

    // Form fields
    @State private var name: String = ""
    @State private var accommodationType: AccommodationType = .hotel
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var website: String = ""

    @State private var confirmationNumber: String = ""
    @State private var checkInDate: Date = Date()
    @State private var hasCheckInDate: Bool = false
    @State private var checkOutDate: Date = Date()
    @State private var hasCheckOutDate: Bool = false
    @State private var checkInTime: String = ""
    @State private var checkOutTime: String = ""

    @State private var nightlyRate: String = ""
    @State private var currency: String = "USD"
    @State private var groupRate: Bool = false
    @State private var groupRateCode: String = ""
    @State private var isPaid: Bool = false

    @State private var roomCount: Int = 1
    @State private var roomType: String = ""
    @State private var roomAssignmentsNotes: String = ""

    @State private var hasShuttle: Bool = false
    @State private var shuttleNotes: String = ""
    @State private var hasGearStorage: Bool = false
    @State private var hasLaundry: Bool = false
    @State private var hasRestaurant: Bool = false
    @State private var hasWifi: Bool = false
    @State private var hasParking: Bool = false

    @State private var nearbyServices: String = ""
    @State private var bookingNotes: String = ""
    @State private var notes: String = ""
    @State private var status: AccommodationStatus = .reserved

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "Edit Accommodation" : "New Accommodation"
    }

    private var existingAccommodation: Accommodation? {
        if case .edit(let acc) = mode {
            return acc
        }
        return nil
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Name", text: $name)

                Picker("Type", selection: $accommodationType) {
                    ForEach(AccommodationType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(AccommodationStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            } header: {
                Text("Basic Info")
            }

            // Location
            Section {
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("Country", text: $country)
            } header: {
                Text("Location")
            }

            // Contact
            Section {
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Website", text: $website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Contact")
            }

            // Dates
            Section {
                Toggle("Set Check-in Date", isOn: $hasCheckInDate)
                if hasCheckInDate {
                    DatePicker("Check-in", selection: $checkInDate, displayedComponents: .date)
                    TextField("Check-in Time (e.g., 3:00 PM)", text: $checkInTime)
                }

                Toggle("Set Check-out Date", isOn: $hasCheckOutDate)
                if hasCheckOutDate {
                    DatePicker("Check-out", selection: $checkOutDate, displayedComponents: .date)
                    TextField("Check-out Time (e.g., 11:00 AM)", text: $checkOutTime)
                }
            } header: {
                Text("Dates")
            }

            // Booking
            Section {
                TextField("Confirmation Number", text: $confirmationNumber)

                Toggle("Group Rate", isOn: $groupRate)
                if groupRate {
                    TextField("Group Code", text: $groupRateCode)
                }

                TextField("Nightly Rate", text: $nightlyRate)
                    .keyboardType(.decimalPad)

                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("CAD").tag("CAD")
                    Text("AUD").tag("AUD")
                }

                Toggle("Paid", isOn: $isPaid)
            } header: {
                Text("Booking")
            }

            // Rooms
            Section {
                Stepper("Rooms: \(roomCount)", value: $roomCount, in: 1...20)
                TextField("Room Type", text: $roomType)

                VStack(alignment: .leading) {
                    Text("Room Assignments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $roomAssignmentsNotes)
                        .frame(minHeight: 60)
                }
            } header: {
                Text("Rooms")
            }

            // Amenities
            Section {
                Toggle("Shuttle Service", isOn: $hasShuttle)
                if hasShuttle {
                    TextField("Shuttle Notes", text: $shuttleNotes)
                }
                Toggle("Gear Storage", isOn: $hasGearStorage)
                Toggle("Laundry", isOn: $hasLaundry)
                Toggle("Restaurant", isOn: $hasRestaurant)
                Toggle("WiFi", isOn: $hasWifi)
                Toggle("Parking", isOn: $hasParking)
            } header: {
                Text("Amenities")
            }

            // Notes
            Section {
                VStack(alignment: .leading) {
                    Text("Nearby Services")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $nearbyServices)
                        .frame(minHeight: 40)
                }

                VStack(alignment: .leading) {
                    Text("Booking Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $bookingNotes)
                        .frame(minHeight: 40)
                }

                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveAccommodation()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let acc = existingAccommodation else { return }

        name = acc.name
        accommodationType = acc.accommodationType
        address = acc.address
        city = acc.city
        country = acc.country
        phone = acc.phone
        email = acc.email
        website = acc.website
        confirmationNumber = acc.confirmationNumber
        if let checkIn = acc.checkInDate {
            checkInDate = checkIn
            hasCheckInDate = true
        }
        if let checkOut = acc.checkOutDate {
            checkOutDate = checkOut
            hasCheckOutDate = true
        }
        checkInTime = acc.checkInTime
        checkOutTime = acc.checkOutTime
        if let rate = acc.nightlyRate {
            nightlyRate = "\(rate)"
        }
        currency = acc.currency
        groupRate = acc.groupRate
        groupRateCode = acc.groupRateCode
        isPaid = acc.isPaid
        roomCount = acc.roomCount
        roomType = acc.roomType
        roomAssignmentsNotes = acc.roomAssignmentsNotes
        hasShuttle = acc.hasShuttle
        shuttleNotes = acc.shuttleNotes
        hasGearStorage = acc.hasGearStorage
        hasLaundry = acc.hasLaundry
        hasRestaurant = acc.hasRestaurant
        hasWifi = acc.hasWifi
        hasParking = acc.hasParking
        nearbyServices = acc.nearbyServices
        bookingNotes = acc.bookingNotes
        notes = acc.notes
        status = acc.status
    }

    // MARK: - Save

    private func saveAccommodation() {
        if let existing = existingAccommodation {
            existing.name = name
            existing.accommodationType = accommodationType
            existing.address = address
            existing.city = city
            existing.country = country
            existing.phone = phone
            existing.email = email
            existing.website = website
            existing.confirmationNumber = confirmationNumber
            existing.checkInDate = hasCheckInDate ? checkInDate : nil
            existing.checkOutDate = hasCheckOutDate ? checkOutDate : nil
            existing.checkInTime = checkInTime
            existing.checkOutTime = checkOutTime
            existing.nightlyRate = Decimal(string: nightlyRate)
            existing.currency = currency
            existing.groupRate = groupRate
            existing.groupRateCode = groupRateCode
            existing.isPaid = isPaid
            existing.roomCount = roomCount
            existing.roomType = roomType
            existing.roomAssignmentsNotes = roomAssignmentsNotes
            existing.hasShuttle = hasShuttle
            existing.shuttleNotes = shuttleNotes
            existing.hasGearStorage = hasGearStorage
            existing.hasLaundry = hasLaundry
            existing.hasRestaurant = hasRestaurant
            existing.hasWifi = hasWifi
            existing.hasParking = hasParking
            existing.nearbyServices = nearbyServices
            existing.bookingNotes = bookingNotes
            existing.notes = notes
            existing.status = status

            viewModel.updateAccommodation(existing, in: expedition)
        } else {
            let acc = Accommodation(name: name, accommodationType: accommodationType, city: city)
            acc.address = address
            acc.country = country
            acc.phone = phone
            acc.email = email
            acc.website = website
            acc.confirmationNumber = confirmationNumber
            acc.checkInDate = hasCheckInDate ? checkInDate : nil
            acc.checkOutDate = hasCheckOutDate ? checkOutDate : nil
            acc.checkInTime = checkInTime
            acc.checkOutTime = checkOutTime
            acc.nightlyRate = Decimal(string: nightlyRate)
            acc.currency = currency
            acc.groupRate = groupRate
            acc.groupRateCode = groupRateCode
            acc.isPaid = isPaid
            acc.roomCount = roomCount
            acc.roomType = roomType
            acc.roomAssignmentsNotes = roomAssignmentsNotes
            acc.hasShuttle = hasShuttle
            acc.shuttleNotes = shuttleNotes
            acc.hasGearStorage = hasGearStorage
            acc.hasLaundry = hasLaundry
            acc.hasRestaurant = hasRestaurant
            acc.hasWifi = hasWifi
            acc.hasParking = hasParking
            acc.nearbyServices = nearbyServices
            acc.bookingNotes = bookingNotes
            acc.notes = notes
            acc.status = status

            viewModel.addAccommodation(acc, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AccommodationFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            viewModel: AccommodationViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
