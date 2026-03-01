import SwiftUI
import SwiftData

enum TransportFormMode {
    case create
    case edit(TransportLeg)
}

struct TransportFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: TransportFormMode
    let expedition: Expedition
    var viewModel: TransportViewModel

    // Form fields
    @State private var transportType: TransportType = .flight
    @State private var carrier: String = ""
    @State private var bookingReference: String = ""

    @State private var departureLocation: String = ""
    @State private var departureCode: String = ""
    @State private var departureTime: Date = Date()
    @State private var hasDepartureTime: Bool = false

    @State private var arrivalLocation: String = ""
    @State private var arrivalCode: String = ""
    @State private var arrivalTime: Date = Date()
    @State private var hasArrivalTime: Bool = false

    @State private var flightNumber: String = ""
    @State private var airline: String = ""
    @State private var seatAssignment: String = ""

    @State private var vehicleInfo: String = ""
    @State private var driverContact: String = ""
    @State private var pickupInstructions: String = ""

    @State private var cost: String = ""
    @State private var currency: String = "USD"
    @State private var isPaid: Bool = false

    @State private var status: TransportStatus = .booked
    @State private var notes: String = ""

    @State private var selectedParticipant: Participant?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "Edit Transport" : "New Transport"
    }

    private var existingLeg: TransportLeg? {
        if case .edit(let leg) = mode {
            return leg
        }
        return nil
    }

    private var isFlightType: Bool {
        transportType == .flight || transportType == .charter ||
        transportType == .bushPlane || transportType == .helicopter
    }

    var body: some View {
        Form {
            // Transport Type
            Section {
                Picker("Type", selection: $transportType) {
                    ForEach(TransportType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                TextField("Carrier/Company", text: $carrier)
                TextField("Booking Reference", text: $bookingReference)
            } header: {
                Text("Transport Type")
            }

            // Departure
            Section {
                TextField("Location", text: $departureLocation)
                if isFlightType {
                    TextField("Airport Code", text: $departureCode)
                        .textInputAutocapitalization(.characters)
                }

                Toggle("Set Departure Time", isOn: $hasDepartureTime)
                if hasDepartureTime {
                    DatePicker("Departure", selection: $departureTime, displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("Departure")
            }

            // Arrival
            Section {
                TextField("Location", text: $arrivalLocation)
                if isFlightType {
                    TextField("Airport Code", text: $arrivalCode)
                        .textInputAutocapitalization(.characters)
                }

                Toggle("Set Arrival Time", isOn: $hasArrivalTime)
                if hasArrivalTime {
                    DatePicker("Arrival", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                }
            } header: {
                Text("Arrival")
            }

            // Flight-specific
            if isFlightType {
                Section {
                    TextField("Airline", text: $airline)
                    TextField("Flight Number", text: $flightNumber)
                    TextField("Seat Assignment", text: $seatAssignment)
                } header: {
                    Label("Flight Details", systemImage: "airplane")
                }
            }

            // Ground transport specific
            if !isFlightType {
                Section {
                    TextField("Vehicle Info", text: $vehicleInfo)
                    TextField("Driver Contact", text: $driverContact)
                    VStack(alignment: .leading) {
                        Text("Pickup Instructions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $pickupInstructions)
                            .frame(minHeight: 60)
                    }
                } header: {
                    Label("Ground Transport", systemImage: "car")
                }
            }

            // Cost
            Section {
                TextField("Cost", text: $cost)
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
                Text("Cost")
            }

            // Participant
            Section {
                Picker("Passenger", selection: $selectedParticipant) {
                    Text("None").tag(nil as Participant?)
                    ForEach(expedition.participants ?? []) { participant in
                        Text(participant.name).tag(participant as Participant?)
                    }
                }
            } header: {
                Text("Passenger")
            }

            // Status & Notes
            Section {
                Picker("Status", selection: $status) {
                    ForEach(TransportStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            } header: {
                Text("Status & Notes")
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
                    saveTransport()
                }
                .disabled(departureLocation.isEmpty && arrivalLocation.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let leg = existingLeg else { return }

        transportType = leg.transportType
        carrier = leg.carrier
        bookingReference = leg.bookingReference
        departureLocation = leg.departureLocation
        departureCode = leg.departureCode
        if let dt = leg.departureTime {
            departureTime = dt
            hasDepartureTime = true
        }
        arrivalLocation = leg.arrivalLocation
        arrivalCode = leg.arrivalCode
        if let at = leg.arrivalTime {
            arrivalTime = at
            hasArrivalTime = true
        }
        flightNumber = leg.flightNumber
        airline = leg.airline
        seatAssignment = leg.seatAssignment ?? ""
        vehicleInfo = leg.vehicleInfo ?? ""
        driverContact = leg.driverContact ?? ""
        pickupInstructions = leg.pickupInstructions ?? ""
        if let legCost = leg.cost {
            cost = "\(legCost)"
        }
        currency = leg.currency
        isPaid = leg.isPaid
        status = leg.status
        notes = leg.notes
        selectedParticipant = leg.participant
    }

    // MARK: - Save

    private func saveTransport() {
        if let existing = existingLeg {
            existing.transportType = transportType
            existing.carrier = carrier
            existing.bookingReference = bookingReference
            existing.departureLocation = departureLocation
            existing.departureCode = departureCode
            existing.departureTime = hasDepartureTime ? departureTime : nil
            existing.arrivalLocation = arrivalLocation
            existing.arrivalCode = arrivalCode
            existing.arrivalTime = hasArrivalTime ? arrivalTime : nil
            existing.flightNumber = flightNumber
            existing.airline = airline
            existing.seatAssignment = seatAssignment.isEmpty ? nil : seatAssignment
            existing.vehicleInfo = vehicleInfo.isEmpty ? nil : vehicleInfo
            existing.driverContact = driverContact.isEmpty ? nil : driverContact
            existing.pickupInstructions = pickupInstructions.isEmpty ? nil : pickupInstructions
            existing.cost = Decimal(string: cost)
            existing.currency = currency
            existing.isPaid = isPaid
            existing.status = status
            existing.notes = notes
            existing.participant = selectedParticipant

            viewModel.updateTransportLeg(existing, in: expedition)
        } else {
            let leg = TransportLeg(
                transportType: transportType,
                carrier: carrier,
                departureLocation: departureLocation,
                arrivalLocation: arrivalLocation
            )
            leg.bookingReference = bookingReference
            leg.departureCode = departureCode
            leg.departureTime = hasDepartureTime ? departureTime : nil
            leg.arrivalCode = arrivalCode
            leg.arrivalTime = hasArrivalTime ? arrivalTime : nil
            leg.flightNumber = flightNumber
            leg.airline = airline
            leg.seatAssignment = seatAssignment.isEmpty ? nil : seatAssignment
            leg.vehicleInfo = vehicleInfo.isEmpty ? nil : vehicleInfo
            leg.driverContact = driverContact.isEmpty ? nil : driverContact
            leg.pickupInstructions = pickupInstructions.isEmpty ? nil : pickupInstructions
            leg.cost = Decimal(string: cost)
            leg.currency = currency
            leg.isPaid = isPaid
            leg.status = status
            leg.notes = notes
            leg.participant = selectedParticipant

            viewModel.addTransportLeg(leg, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        TransportFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            viewModel: TransportViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
