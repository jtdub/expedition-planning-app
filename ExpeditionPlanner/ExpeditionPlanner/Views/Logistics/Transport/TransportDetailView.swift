import SwiftUI
import SwiftData

struct TransportDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let transportLeg: TransportLeg
    let expedition: Expedition
    var viewModel: TransportViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Schedule
            Section {
                scheduleSection
            } header: {
                Label("Schedule", systemImage: "clock")
            }

            // Booking Details
            if !transportLeg.bookingReference.isEmpty || transportLeg.cost != nil {
                Section {
                    if !transportLeg.bookingReference.isEmpty {
                        LabeledContent("Confirmation", value: transportLeg.bookingReference)
                    }
                    if let cost = transportLeg.cost {
                        LabeledContent("Cost") {
                            Text(formatCurrency(cost, code: transportLeg.currency))
                        }
                    }
                    if transportLeg.cost != nil {
                        LabeledContent("Payment") {
                            Text(transportLeg.isPaid ? "Paid" : "Unpaid")
                                .foregroundStyle(transportLeg.isPaid ? .green : .orange)
                        }
                    }
                } header: {
                    Label("Booking", systemImage: "ticket")
                }
            }

            // Flight-specific
            if transportLeg.transportType == .flight || transportLeg.transportType == .charter {
                Section {
                    if !transportLeg.airline.isEmpty {
                        LabeledContent("Airline", value: transportLeg.airline)
                    }
                    if !transportLeg.flightNumber.isEmpty {
                        LabeledContent("Flight Number", value: transportLeg.flightNumber)
                    }
                    if let aircraft = transportLeg.aircraft, !aircraft.isEmpty {
                        LabeledContent("Aircraft", value: aircraft)
                    }
                    if let seat = transportLeg.seatAssignment, !seat.isEmpty {
                        LabeledContent("Seat", value: seat)
                    }
                } header: {
                    Label("Flight Details", systemImage: "airplane")
                }
            }

            // Ground transport specific
            if transportLeg.vehicleInfo != nil || transportLeg.driverContact != nil {
                Section {
                    if let vehicle = transportLeg.vehicleInfo, !vehicle.isEmpty {
                        LabeledContent("Vehicle", value: vehicle)
                    }
                    if let driver = transportLeg.driverContact, !driver.isEmpty {
                        Button {
                            if let url = URL(string: "tel:\(driver.replacingOccurrences(of: " ", with: ""))") {
                                openURL(url)
                            }
                        } label: {
                            LabeledContent("Driver Contact", value: driver)
                        }
                    }
                    if let instructions = transportLeg.pickupInstructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pickup Instructions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(instructions)
                        }
                    }
                } header: {
                    Label("Ground Transport", systemImage: "car")
                }
            }

            // Participant
            if let participant = transportLeg.participant {
                Section {
                    LabeledContent("Passenger", value: participant.name)
                    if !participant.email.isEmpty {
                        LabeledContent("Email", value: participant.email)
                    }
                } header: {
                    Label("Passenger", systemImage: "person")
                }
            }

            // Notes
            if !transportLeg.notes.isEmpty {
                Section {
                    Text(transportLeg.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Transport", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Transport Details")
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
                TransportFormView(
                    mode: .edit(transportLeg),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Transport?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteTransportLeg(transportLeg, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: transportLeg.transportType.icon)
                .font(.largeTitle)
                .foregroundStyle(typeColor)
                .frame(width: 60, height: 60)
                .background(typeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(transportLeg.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(transportLeg.routeSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(transportLeg.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(spacing: 16) {
            // Departure
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEPARTURE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(transportLeg.departureCode.isEmpty
                        ? transportLeg.departureLocation
                        : transportLeg.departureCode)
                        .font(.title2)
                        .fontWeight(.bold)
                    if !transportLeg.departureCode.isEmpty && !transportLeg.departureLocation.isEmpty {
                        Text(transportLeg.departureLocation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let time = transportLeg.departureTime {
                        Text(time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                }
                Spacer()
            }

            // Duration indicator
            HStack {
                Image(systemName: "arrow.down")
                    .foregroundStyle(.secondary)
                if transportLeg.formattedDuration != "N/A" {
                    Text(transportLeg.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Arrival
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ARRIVAL")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(transportLeg.arrivalCode.isEmpty
                        ? transportLeg.arrivalLocation
                        : transportLeg.arrivalCode)
                        .font(.title2)
                        .fontWeight(.bold)
                    if !transportLeg.arrivalCode.isEmpty && !transportLeg.arrivalLocation.isEmpty {
                        Text(transportLeg.arrivalLocation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let time = transportLeg.arrivalTime {
                        Text(time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private var typeColor: Color {
        switch transportLeg.transportType.color {
        case "blue": return .blue
        case "green": return .green
        case "cyan": return .cyan
        case "orange": return .orange
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch transportLeg.status.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return .secondary
        }
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }
}

#Preview {
    NavigationStack {
        TransportDetailView(
            transportLeg: {
                let leg = TransportLeg(
                    transportType: .flight,
                    carrier: "Alaska Airlines",
                    departureLocation: "Seattle",
                    arrivalLocation: "Fairbanks"
                )
                leg.flightNumber = "AS123"
                leg.airline = "Alaska Airlines"
                leg.departureCode = "SEA"
                leg.arrivalCode = "FAI"
                leg.departureTime = Date()
                leg.arrivalTime = Date().addingTimeInterval(3600 * 3)
                leg.bookingReference = "ABC123"
                leg.status = .confirmed
                return leg
            }(),
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
