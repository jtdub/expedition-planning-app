import SwiftUI
import SwiftData

struct ParticipantDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let participant: Participant
    let expedition: Expedition
    var viewModel: ParticipantViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Contact Info
            Section {
                if !participant.email.isEmpty {
                    Button {
                        if let url = URL(string: "mailto:\(participant.email)") {
                            openURL(url)
                        }
                    } label: {
                        Label(participant.email, systemImage: "envelope")
                    }
                }

                if !participant.phone.isEmpty {
                    Button {
                        if let url = URL(string: "tel:\(participant.phone)") {
                            openURL(url)
                        }
                    } label: {
                        Label(participant.phone, systemImage: "phone")
                    }
                }
            } header: {
                Text("Contact")
            }

            // Travel Info
            if hasArrivalDate || hasDepartureDate || !participant.arrivalFlightInfo.isEmpty {
                Section {
                    if let date = participant.arrivalDate {
                        LabeledContent("Arrival") {
                            Text(date.formatted(date: .long, time: .omitted))
                        }
                    }
                    if !participant.arrivalFlightInfo.isEmpty {
                        LabeledContent("Flight Info", value: participant.arrivalFlightInfo)
                    }
                    if let date = participant.departureDate {
                        LabeledContent("Departure") {
                            Text(date.formatted(date: .long, time: .omitted))
                        }
                    }
                    if !participant.departureFlightInfo.isEmpty {
                        LabeledContent("Flight Info", value: participant.departureFlightInfo)
                    }
                } header: {
                    Text("Travel")
                }
            }

            // Accommodation
            if participant.hotelReservation != nil || participant.roomAssignment != nil {
                Section {
                    if let hotel = participant.hotelReservation {
                        LabeledContent("Hotel", value: hotel)
                    }
                    if let room = participant.roomAssignment {
                        LabeledContent("Room", value: room)
                    }
                } header: {
                    Text("Accommodation")
                }
            }

            // Personal Info
            if participant.dietaryRestrictions != nil || participant.medicalNotes != nil {
                Section {
                    if let dietary = participant.dietaryRestrictions {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dietary Restrictions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(dietary)
                        }
                    }
                    if let medical = participant.medicalNotes {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medical Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(medical)
                        }
                    }
                } header: {
                    Text("Personal Information")
                }
            }

            // Emergency Contact
            if participant.emergencyContactName != nil || participant.emergencyContactPhone != nil {
                Section {
                    if let name = participant.emergencyContactName {
                        LabeledContent("Name", value: name)
                    }
                    if let phone = participant.emergencyContactPhone {
                        Button {
                            if let url = URL(string: "tel:\(phone)") {
                                openURL(url)
                            }
                        } label: {
                            LabeledContent("Phone") {
                                Text(phone)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } header: {
                    Label("Emergency Contact", systemImage: "exclamationmark.triangle")
                }
            }

            // Status
            Section {
                HStack {
                    Label("Confirmed", systemImage: "checkmark.circle")
                    Spacer()
                    Image(systemName: participant.isConfirmed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(participant.isConfirmed ? .green : .secondary)
                }

                HStack {
                    Label("Paid", systemImage: "dollarsign.circle")
                    Spacer()
                    Image(systemName: participant.hasPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(participant.hasPaid ? .green : .secondary)
                }
            } header: {
                Text("Status")
            }

            // Notes
            if !participant.notes.isEmpty {
                Section {
                    Text(participant.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Participant", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Participant")
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
                ParticipantFormView(
                    mode: .edit(participant),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Participant?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteParticipant(participant, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.2))
                Text(participant.initials)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(roleColor)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(participant.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: participant.role.icon)
                    Text(participant.role.rawValue)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !participant.groupAssignment.isEmpty {
                    Text("Group: \(participant.groupAssignment)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var hasArrivalDate: Bool {
        participant.arrivalDate != nil
    }

    private var hasDepartureDate: Bool {
        participant.departureDate != nil
    }

    private var roleColor: Color {
        switch participant.role {
        case .guide: return .orange
        case .assistantGuide: return .yellow
        case .participant: return .blue
        case .client: return .purple
        case .researcher: return .teal
        case .photographer: return .pink
        case .support: return .green
        }
    }
}

#Preview {
    NavigationStack {
        ParticipantDetailView(
            participant: {
                let participant = Participant(name: "John Doe", email: "john@example.com", role: .guide)
                participant.phone = "+1 555-1234"
                participant.isConfirmed = true
                participant.hasPaid = true
                participant.groupAssignment = "Group A"
                participant.emergencyContactName = "Jane Doe"
                participant.emergencyContactPhone = "+1 555-5678"
                return participant
            }(),
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ParticipantViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
