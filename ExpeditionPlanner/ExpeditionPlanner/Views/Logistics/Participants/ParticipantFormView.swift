import SwiftUI
import SwiftData

enum ParticipantFormMode {
    case create
    case edit(Participant)
}

struct ParticipantFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: ParticipantFormMode
    let expedition: Expedition
    var viewModel: ParticipantViewModel

    // Basic info
    @State private var name = ""
    @State private var nickname = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: ParticipantRole = .participant
    @State private var groupAssignment = ""
    @State private var scheduleType = ""

    // Travel info
    @State private var arrivalFlightInfo = ""
    @State private var departureFlightInfo = ""
    @State private var arrivalDate: Date = Date()
    @State private var departureDate: Date = Date()
    @State private var hasArrivalDate = false
    @State private var hasDepartureDate = false

    // Accommodation
    @State private var hotelReservation = ""
    @State private var roomAssignment = ""

    // Personal info
    @State private var dietaryRestrictions = ""
    @State private var medicalNotes = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""

    // Status
    @State private var isConfirmed = false
    @State private var hasPaid = false
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingParticipant: Participant? {
        if case .edit(let participant) = mode { return participant }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Full Name", text: $name)
                TextField("Nickname (optional)", text: $nickname)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)

                Picker("Role", selection: $role) {
                    ForEach(ParticipantRole.allCases, id: \.self) { role in
                        Label(role.rawValue, systemImage: role.icon)
                            .tag(role)
                    }
                }

                TextField("Group Assignment", text: $groupAssignment)
                TextField("Schedule Type", text: $scheduleType)
            } header: {
                Text("Basic Information")
            }

            // Travel Info
            Section {
                Toggle("Has Arrival Date", isOn: $hasArrivalDate)
                if hasArrivalDate {
                    DatePicker("Arrival Date", selection: $arrivalDate, displayedComponents: .date)
                }
                TextField("Arrival Flight Info", text: $arrivalFlightInfo)

                Toggle("Has Departure Date", isOn: $hasDepartureDate)
                if hasDepartureDate {
                    DatePicker("Departure Date", selection: $departureDate, displayedComponents: .date)
                }
                TextField("Departure Flight Info", text: $departureFlightInfo)
            } header: {
                Text("Travel Information")
            }

            // Accommodation
            Section {
                TextField("Hotel Reservation", text: $hotelReservation)
                TextField("Room Assignment", text: $roomAssignment)
            } header: {
                Text("Accommodation")
            }

            // Personal Info
            Section {
                TextField("Dietary Restrictions", text: $dietaryRestrictions, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Medical Notes", text: $medicalNotes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Personal Information")
            } footer: {
                Text("This information is kept confidential and used for safety planning.")
            }

            // Emergency Contact
            Section {
                TextField("Emergency Contact Name", text: $emergencyContactName)
                TextField("Emergency Contact Phone", text: $emergencyContactPhone)
                    .keyboardType(.phonePad)
            } header: {
                Text("Emergency Contact")
            }

            // Status
            Section {
                Toggle("Confirmed", isOn: $isConfirmed)
                Toggle("Paid", isOn: $hasPaid)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Status")
            }
        }
        .navigationTitle(isEditing ? "Edit Participant" : "Add Participant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveParticipant()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let participant = editingParticipant {
                loadParticipant(participant)
            }
        }
    }

    // MARK: - Load/Save

    private func loadParticipant(_ participant: Participant) {
        name = participant.name
        nickname = participant.nickname ?? ""
        email = participant.email
        phone = participant.phone
        role = participant.role
        groupAssignment = participant.groupAssignment
        scheduleType = participant.scheduleType
        arrivalFlightInfo = participant.arrivalFlightInfo
        departureFlightInfo = participant.departureFlightInfo
        if let date = participant.arrivalDate {
            arrivalDate = date
            hasArrivalDate = true
        }
        if let date = participant.departureDate {
            departureDate = date
            hasDepartureDate = true
        }
        hotelReservation = participant.hotelReservation ?? ""
        roomAssignment = participant.roomAssignment ?? ""
        dietaryRestrictions = participant.dietaryRestrictions ?? ""
        medicalNotes = participant.medicalNotes ?? ""
        emergencyContactName = participant.emergencyContactName ?? ""
        emergencyContactPhone = participant.emergencyContactPhone ?? ""
        isConfirmed = participant.isConfirmed
        hasPaid = participant.hasPaid
        notes = participant.notes
    }

    private func saveParticipant() {
        let participant: Participant
        if let existing = editingParticipant {
            participant = existing
        } else {
            participant = Participant()
        }

        participant.name = name
        participant.nickname = nickname.isEmpty ? nil : nickname
        participant.email = email
        participant.phone = phone
        participant.role = role
        participant.groupAssignment = groupAssignment
        participant.scheduleType = scheduleType
        participant.arrivalFlightInfo = arrivalFlightInfo
        participant.departureFlightInfo = departureFlightInfo
        participant.arrivalDate = hasArrivalDate ? arrivalDate : nil
        participant.departureDate = hasDepartureDate ? departureDate : nil
        participant.hotelReservation = hotelReservation.isEmpty ? nil : hotelReservation
        participant.roomAssignment = roomAssignment.isEmpty ? nil : roomAssignment
        participant.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
        participant.medicalNotes = medicalNotes.isEmpty ? nil : medicalNotes
        participant.emergencyContactName = emergencyContactName.isEmpty ? nil : emergencyContactName
        participant.emergencyContactPhone = emergencyContactPhone.isEmpty ? nil : emergencyContactPhone
        participant.isConfirmed = isConfirmed
        participant.hasPaid = hasPaid
        participant.notes = notes

        if isEditing {
            viewModel.updateParticipant(participant, in: expedition)
        } else {
            viewModel.addParticipant(participant, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ParticipantFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ParticipantViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
