import SwiftUI
import SwiftData

enum SatelliteDeviceFormMode {
    case create
    case edit(SatelliteDevice)
}

struct SatelliteDeviceFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: SatelliteDeviceFormMode
    let expedition: Expedition
    var viewModel: SatelliteDeviceViewModel

    // Form fields
    @State private var name: String = ""
    @State private var deviceType: SatelliteDeviceType = .inReach
    @State private var deviceId: String = ""
    @State private var imeiNumber: String = ""
    @State private var serialNumber: String = ""

    @State private var subscriptionPlan: String = ""
    @State private var subscriptionExpiry: Date = Date()
    @State private var hasSubscriptionExpiry: Bool = false
    @State private var monthlyFee: String = ""
    @State private var currency: String = "USD"

    @State private var isRented: Bool = false
    @State private var rentalCompany: String = ""
    @State private var rentalContact: String = ""
    @State private var rentalPhone: String = ""
    @State private var pickupLocation: String = ""
    @State private var pickupDate: Date = Date()
    @State private var hasPickupDate: Bool = false
    @State private var pickupInstructions: String = ""
    @State private var returnLocation: String = ""
    @State private var returnDate: Date = Date()
    @State private var hasReturnDate: Bool = false
    @State private var returnInstructions: String = ""
    @State private var rentalCost: String = ""

    @State private var checkInSchedule: String = ""
    @State private var checkInRecipients: String = ""
    @State private var okMessageText: String = "All OK - checking in as scheduled"

    @State private var batteryType: String = ""
    @State private var batteryLife: String = ""
    @State private var chargingNotes: String = ""

    @State private var radioFrequencies: String = ""
    @State private var callSign: String = ""

    @State private var assignedToParticipant: String = ""
    @State private var status: DeviceStatus = .available
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "Edit Device" : "New Device"
    }

    private var existingDevice: SatelliteDevice? {
        if case .edit(let device) = mode {
            return device
        }
        return nil
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Name", text: $name)

                Picker("Type", selection: $deviceType) {
                    ForEach(SatelliteDeviceType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(DeviceStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            } header: {
                Text("Basic Info")
            }

            // Device Identification
            Section {
                TextField("Device ID", text: $deviceId)
                TextField("IMEI Number", text: $imeiNumber)
                TextField("Serial Number", text: $serialNumber)
            } header: {
                Text("Device Identification")
            }

            // Assignment
            Section {
                Picker("Assigned To", selection: $assignedToParticipant) {
                    Text("Unassigned").tag("")
                    ForEach(expedition.participants ?? []) { participant in
                        Text(participant.name).tag(participant.name)
                    }
                }
            } header: {
                Text("Assignment")
            }

            // Subscription
            Section {
                TextField("Plan", text: $subscriptionPlan)

                Toggle("Set Expiry Date", isOn: $hasSubscriptionExpiry)
                if hasSubscriptionExpiry {
                    DatePicker("Expires", selection: $subscriptionExpiry, displayedComponents: .date)
                }

                TextField("Monthly Fee", text: $monthlyFee)
                    .keyboardType(.decimalPad)

                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("CAD").tag("CAD")
                }
            } header: {
                Text("Subscription")
            }

            // Rental
            Section {
                Toggle("Rented Device", isOn: $isRented)

                if isRented {
                    TextField("Rental Company", text: $rentalCompany)
                    TextField("Contact Name", text: $rentalContact)
                    TextField("Contact Phone", text: $rentalPhone)
                        .keyboardType(.phonePad)

                    Toggle("Set Pickup Date", isOn: $hasPickupDate)
                    if hasPickupDate {
                        DatePicker("Pickup Date", selection: $pickupDate, displayedComponents: .date)
                    }
                    TextField("Pickup Location", text: $pickupLocation)
                    VStack(alignment: .leading) {
                        Text("Pickup Instructions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $pickupInstructions)
                            .frame(minHeight: 40)
                    }

                    Toggle("Set Return Date", isOn: $hasReturnDate)
                    if hasReturnDate {
                        DatePicker("Return Date", selection: $returnDate, displayedComponents: .date)
                    }
                    TextField("Return Location", text: $returnLocation)
                    VStack(alignment: .leading) {
                        Text("Return Instructions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $returnInstructions)
                            .frame(minHeight: 40)
                    }

                    TextField("Rental Cost", text: $rentalCost)
                        .keyboardType(.decimalPad)
                }
            } header: {
                Text("Rental")
            }

            // Check-in
            Section {
                TextField("Schedule (e.g., Daily at 7pm)", text: $checkInSchedule)
                TextField("Recipients (comma-separated)", text: $checkInRecipients)
                VStack(alignment: .leading) {
                    Text("OK Message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $okMessageText)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Check-in Configuration")
            }

            // Radio (for VHF/HF)
            if deviceType == .vhfRadio || deviceType == .hfRadio {
                Section {
                    TextField("Call Sign", text: $callSign)
                    TextField("Frequencies (comma-separated)", text: $radioFrequencies)
                } header: {
                    Text("Radio Configuration")
                }
            }

            // Battery
            Section {
                TextField("Battery Type", text: $batteryType)
                TextField("Battery Life", text: $batteryLife)
                VStack(alignment: .leading) {
                    Text("Charging Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $chargingNotes)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Power")
            }

            // Notes
            Section {
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
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
                    saveDevice()
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let device = existingDevice else { return }

        name = device.name
        deviceType = device.deviceType
        deviceId = device.deviceId
        imeiNumber = device.imeiNumber
        serialNumber = device.serialNumber
        subscriptionPlan = device.subscriptionPlan
        if let expiry = device.subscriptionExpiry {
            subscriptionExpiry = expiry
            hasSubscriptionExpiry = true
        }
        if let fee = device.monthlyFee {
            monthlyFee = "\(fee)"
        }
        currency = device.currency
        isRented = device.isRented
        rentalCompany = device.rentalCompany
        rentalContact = device.rentalContact
        rentalPhone = device.rentalPhone
        pickupLocation = device.pickupLocation
        if let pickup = device.pickupDate {
            pickupDate = pickup
            hasPickupDate = true
        }
        pickupInstructions = device.pickupInstructions
        returnLocation = device.returnLocation
        if let returnD = device.returnDate {
            returnDate = returnD
            hasReturnDate = true
        }
        returnInstructions = device.returnInstructions
        if let cost = device.rentalCost {
            rentalCost = "\(cost)"
        }
        checkInSchedule = device.checkInSchedule
        checkInRecipients = device.checkInRecipients
        okMessageText = device.okMessageText
        batteryType = device.batteryType
        batteryLife = device.batteryLife
        chargingNotes = device.chargingNotes
        radioFrequencies = device.radioFrequencies
        callSign = device.callSign
        assignedToParticipant = device.assignedToParticipant
        status = device.status
        notes = device.notes
    }

    // MARK: - Save

    private func saveDevice() {
        if let existing = existingDevice {
            existing.name = name
            existing.deviceType = deviceType
            existing.deviceId = deviceId
            existing.imeiNumber = imeiNumber
            existing.serialNumber = serialNumber
            existing.subscriptionPlan = subscriptionPlan
            existing.subscriptionExpiry = hasSubscriptionExpiry ? subscriptionExpiry : nil
            existing.monthlyFee = Decimal(string: monthlyFee)
            existing.currency = currency
            existing.isRented = isRented
            existing.rentalCompany = rentalCompany
            existing.rentalContact = rentalContact
            existing.rentalPhone = rentalPhone
            existing.pickupLocation = pickupLocation
            existing.pickupDate = hasPickupDate ? pickupDate : nil
            existing.pickupInstructions = pickupInstructions
            existing.returnLocation = returnLocation
            existing.returnDate = hasReturnDate ? returnDate : nil
            existing.returnInstructions = returnInstructions
            existing.rentalCost = Decimal(string: rentalCost)
            existing.checkInSchedule = checkInSchedule
            existing.checkInRecipients = checkInRecipients
            existing.okMessageText = okMessageText
            existing.batteryType = batteryType
            existing.batteryLife = batteryLife
            existing.chargingNotes = chargingNotes
            existing.radioFrequencies = radioFrequencies
            existing.callSign = callSign
            existing.assignedToParticipant = assignedToParticipant
            existing.status = status
            existing.notes = notes

            viewModel.updateDevice(existing, in: expedition)
        } else {
            let device = SatelliteDevice(name: name, deviceType: deviceType)
            device.deviceId = deviceId
            device.imeiNumber = imeiNumber
            device.serialNumber = serialNumber
            device.subscriptionPlan = subscriptionPlan
            device.subscriptionExpiry = hasSubscriptionExpiry ? subscriptionExpiry : nil
            device.monthlyFee = Decimal(string: monthlyFee)
            device.currency = currency
            device.isRented = isRented
            device.rentalCompany = rentalCompany
            device.rentalContact = rentalContact
            device.rentalPhone = rentalPhone
            device.pickupLocation = pickupLocation
            device.pickupDate = hasPickupDate ? pickupDate : nil
            device.pickupInstructions = pickupInstructions
            device.returnLocation = returnLocation
            device.returnDate = hasReturnDate ? returnDate : nil
            device.returnInstructions = returnInstructions
            device.rentalCost = Decimal(string: rentalCost)
            device.checkInSchedule = checkInSchedule
            device.checkInRecipients = checkInRecipients
            device.okMessageText = okMessageText
            device.batteryType = batteryType
            device.batteryLife = batteryLife
            device.chargingNotes = chargingNotes
            device.radioFrequencies = radioFrequencies
            device.callSign = callSign
            device.assignedToParticipant = assignedToParticipant
            device.status = status
            device.notes = notes

            viewModel.addDevice(device, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        SatelliteDeviceFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            viewModel: SatelliteDeviceViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
