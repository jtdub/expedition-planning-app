import SwiftUI
import SwiftData

struct AccommodationDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let accommodation: Accommodation
    let expedition: Expedition
    var viewModel: AccommodationViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Dates
            if accommodation.checkInDate != nil || accommodation.checkOutDate != nil {
                Section {
                    if let checkIn = accommodation.checkInDate {
                        LabeledContent("Check-in") {
                            VStack(alignment: .trailing) {
                                Text(checkIn.formatted(date: .long, time: .omitted))
                                if !accommodation.checkInTime.isEmpty {
                                    Text(accommodation.checkInTime)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if let checkOut = accommodation.checkOutDate {
                        LabeledContent("Check-out") {
                            VStack(alignment: .trailing) {
                                Text(checkOut.formatted(date: .long, time: .omitted))
                                if !accommodation.checkOutTime.isEmpty {
                                    Text(accommodation.checkOutTime)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if accommodation.numberOfNights > 0 {
                        LabeledContent("Duration", value: "\(accommodation.numberOfNights) nights")
                    }
                } header: {
                    Label("Dates", systemImage: "calendar")
                }
            }

            // Contact
            Section {
                if !accommodation.phone.isEmpty {
                    Button {
                        if let url = URL(string: "tel:\(accommodation.phone.replacingOccurrences(of: " ", with: ""))") {
                            openURL(url)
                        }
                    } label: {
                        Label(accommodation.phone, systemImage: "phone")
                    }
                }
                if !accommodation.email.isEmpty {
                    Button {
                        if let url = URL(string: "mailto:\(accommodation.email)") {
                            openURL(url)
                        }
                    } label: {
                        Label(accommodation.email, systemImage: "envelope")
                    }
                }
                if !accommodation.website.isEmpty {
                    Button {
                        if let url = URL(string: accommodation.website) {
                            openURL(url)
                        }
                    } label: {
                        Label("Website", systemImage: "globe")
                    }
                }
                if !accommodation.address.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(accommodation.displayAddress)
                    }
                }
            } header: {
                Label("Contact", systemImage: "phone")
            }

            // Booking
            if !accommodation.confirmationNumber.isEmpty || accommodation.totalCost != nil {
                Section {
                    if !accommodation.confirmationNumber.isEmpty {
                        LabeledContent("Confirmation #", value: accommodation.confirmationNumber)
                    }
                    if accommodation.groupRate {
                        LabeledContent("Group Rate") {
                            Text(accommodation.groupRateCode.isEmpty ? "Yes" : accommodation.groupRateCode)
                        }
                    }
                    if let rate = accommodation.nightlyRate {
                        LabeledContent("Nightly Rate") {
                            Text(formatCurrency(rate, code: accommodation.currency))
                        }
                    }
                    if let total = accommodation.calculatedTotalCost {
                        LabeledContent("Total") {
                            Text(formatCurrency(total, code: accommodation.currency))
                                .fontWeight(.semibold)
                        }
                    }
                    LabeledContent("Payment") {
                        Text(accommodation.isPaid ? "Paid" : "Unpaid")
                            .foregroundStyle(accommodation.isPaid ? .green : .orange)
                    }
                } header: {
                    Label("Booking", systemImage: "creditcard")
                }
            }

            // Amenities
            if !accommodation.availableAmenities.isEmpty {
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(accommodation.availableAmenities, id: \.self) { amenity in
                            HStack {
                                Image(systemName: iconForAmenity(amenity))
                                    .foregroundStyle(.green)
                                Text(amenity)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                } header: {
                    Label("Amenities", systemImage: "list.bullet")
                }
            }

            // Room info
            if accommodation.roomCount > 1 || !accommodation.roomType.isEmpty {
                Section {
                    if accommodation.roomCount > 1 {
                        LabeledContent("Rooms", value: "\(accommodation.roomCount)")
                    }
                    if !accommodation.roomType.isEmpty {
                        LabeledContent("Room Type", value: accommodation.roomType)
                    }
                    if !accommodation.roomAssignmentsNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Assignments")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(accommodation.roomAssignmentsNotes)
                        }
                    }
                } header: {
                    Label("Rooms", systemImage: "bed.double")
                }
            }

            // Nearby services
            if !accommodation.nearbyServices.isEmpty {
                Section {
                    Text(accommodation.nearbyServices)
                } header: {
                    Label("Nearby Services", systemImage: "mappin.and.ellipse")
                }
            }

            // Booking notes
            if !accommodation.bookingNotes.isEmpty {
                Section {
                    Text(accommodation.bookingNotes)
                } header: {
                    Label("Booking Notes", systemImage: "note.text")
                }
            }

            // Notes
            if !accommodation.notes.isEmpty {
                Section {
                    Text(accommodation.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Accommodation", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Accommodation")
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
                AccommodationFormView(
                    mode: .edit(accommodation),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Accommodation?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAccommodation(accommodation, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: accommodation.accommodationType.icon)
                .font(.largeTitle)
                .foregroundStyle(typeColor)
                .frame(width: 60, height: 60)
                .background(typeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(accommodation.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if !accommodation.city.isEmpty {
                    Text(accommodation.city)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(accommodation.status.rawValue)
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

    // MARK: - Helpers

    private var typeColor: Color {
        switch accommodation.accommodationType.color {
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "green": return .green
        case "orange": return .orange
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch accommodation.status.color {
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

    private func iconForAmenity(_ amenity: String) -> String {
        switch amenity.lowercased() {
        case "shuttle": return "bus"
        case "gear storage": return "shippingbox"
        case "laundry": return "washer"
        case "restaurant": return "fork.knife"
        case "wifi": return "wifi"
        case "parking": return "car"
        default: return "checkmark"
        }
    }
}

#Preview {
    NavigationStack {
        AccommodationDetailView(
            accommodation: {
                let acc = Accommodation(name: "La Quinta Inn", accommodationType: .hotel, city: "Fairbanks")
                acc.checkInDate = Date()
                acc.checkOutDate = Date().addingTimeInterval(86400 * 2)
                acc.phone = "+1 907-555-1234"
                acc.confirmationNumber = "ABC123456"
                acc.hasShuttle = true
                acc.hasWifi = true
                acc.status = .confirmed
                return acc
            }(),
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
