import SwiftUI
import SwiftData

struct SatelliteDeviceDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let device: SatelliteDevice
    let expedition: Expedition
    var viewModel: SatelliteDeviceViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Capabilities
            Section {
                HStack(spacing: 16) {
                    CapabilityBadge(
                        title: "2-Way Messaging",
                        isAvailable: device.deviceType.hasTwoWayMessaging,
                        icon: "message"
                    )
                    CapabilityBadge(
                        title: "GPS Tracking",
                        isAvailable: device.deviceType.hasTracking,
                        icon: "location"
                    )
                }
            } header: {
                Text("Capabilities")
            }

            // Device Info
            Section {
                if !device.deviceId.isEmpty {
                    LabeledContent("Device ID", value: device.deviceId)
                }
                if !device.imeiNumber.isEmpty {
                    LabeledContent("IMEI", value: device.imeiNumber)
                }
                if !device.serialNumber.isEmpty {
                    LabeledContent("Serial Number", value: device.serialNumber)
                }
            } header: {
                Label("Device Info", systemImage: "info.circle")
            }

            // Assignment
            if !device.assignedToParticipant.isEmpty {
                Section {
                    LabeledContent("Assigned To", value: device.assignedToParticipant)
                } header: {
                    Label("Assignment", systemImage: "person")
                }
            }

            // Subscription
            if !device.subscriptionPlan.isEmpty || device.subscriptionExpiry != nil {
                Section {
                    if !device.subscriptionPlan.isEmpty {
                        LabeledContent("Plan", value: device.subscriptionPlan)
                    }
                    if let expiry = device.subscriptionExpiry {
                        LabeledContent("Expires") {
                            Text(expiry.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(device.isSubscriptionActive ? .primary : .red)
                        }
                    }
                    if let fee = device.monthlyFee {
                        LabeledContent("Monthly Fee") {
                            Text(formatCurrency(fee, code: device.currency))
                        }
                    }
                } header: {
                    Label("Subscription", systemImage: "creditcard")
                }
            }

            // Rental Info
            if device.isRented {
                Section {
                    if !device.rentalCompany.isEmpty {
                        LabeledContent("Company", value: device.rentalCompany)
                    }
                    if !device.rentalContact.isEmpty {
                        LabeledContent("Contact", value: device.rentalContact)
                    }
                    if !device.rentalPhone.isEmpty {
                        Button {
                            if let url = URL(string: "tel:\(device.rentalPhone)") {
                                openURL(url)
                            }
                        } label: {
                            LabeledContent("Phone", value: device.rentalPhone)
                        }
                    }
                    if let pickup = device.pickupDate {
                        LabeledContent("Pickup Date") {
                            Text(pickup.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    if !device.pickupLocation.isEmpty {
                        LabeledContent("Pickup Location", value: device.pickupLocation)
                    }
                    if !device.pickupInstructions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pickup Instructions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.pickupInstructions)
                        }
                    }
                    if let returnD = device.returnDate {
                        LabeledContent("Return Date") {
                            Text(returnD.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    if !device.returnLocation.isEmpty {
                        LabeledContent("Return Location", value: device.returnLocation)
                    }
                    if let cost = device.rentalCost {
                        LabeledContent("Rental Cost") {
                            Text(formatCurrency(cost, code: device.currency))
                        }
                    }
                } header: {
                    Label("Rental Info", systemImage: "tag")
                }
            }

            // Check-in Configuration
            if !device.checkInSchedule.isEmpty || !device.okMessageText.isEmpty {
                Section {
                    if !device.checkInSchedule.isEmpty {
                        LabeledContent("Schedule", value: device.checkInSchedule)
                    }
                    if !device.checkInRecipients.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recipients")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.checkInRecipients)
                        }
                    }
                    if !device.okMessageText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OK Message")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.okMessageText)
                        }
                    }
                } header: {
                    Label("Check-in Config", systemImage: "checkmark.message")
                }
            }

            // Radio frequencies
            if !device.radioFrequencies.isEmpty || !device.callSign.isEmpty {
                Section {
                    if !device.callSign.isEmpty {
                        LabeledContent("Call Sign", value: device.callSign)
                    }
                    if !device.radioFrequencies.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Frequencies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.radioFrequencies)
                        }
                    }
                } header: {
                    Label("Radio", systemImage: "radio")
                }
            }

            // Battery
            if !device.batteryType.isEmpty || !device.batteryLife.isEmpty {
                Section {
                    if !device.batteryType.isEmpty {
                        LabeledContent("Battery Type", value: device.batteryType)
                    }
                    if !device.batteryLife.isEmpty {
                        LabeledContent("Battery Life", value: device.batteryLife)
                    }
                    if !device.chargingNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Charging Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.chargingNotes)
                        }
                    }
                } header: {
                    Label("Power", systemImage: "battery.100")
                }
            }

            // Notes
            if !device.notes.isEmpty {
                Section {
                    Text(device.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Device", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Device Details")
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
                SatelliteDeviceFormView(
                    mode: .edit(device),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Device?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteDevice(device, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: device.deviceType.icon)
                .font(.largeTitle)
                .foregroundStyle(typeColor)
                .frame(width: 60, height: 60)
                .background(typeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(device.deviceType.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(device.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    if device.isRented {
                        Text("Rented")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var typeColor: Color {
        switch device.deviceType.color {
        case "orange": return .orange
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "red": return .red
        case "green": return .green
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch device.status.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
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

// MARK: - Capability Badge

struct CapabilityBadge: View {
    let title: String
    let isAvailable: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isAvailable ? .green : .secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(isAvailable ? .primary : .secondary)
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundStyle(isAvailable ? .green : .red)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SatelliteDeviceDetailView(
            device: {
                let device = SatelliteDevice(name: "Team inReach", deviceType: .inReach)
                device.deviceId = "300434012345678"
                device.assignedToParticipant = "John Smith"
                device.checkInSchedule = "Daily at 7pm"
                device.status = .assigned
                return device
            }(),
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
