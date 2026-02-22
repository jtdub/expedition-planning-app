import SwiftUI
import SwiftData

struct ExpeditionDetailView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @ObservedObject private var syncService = SyncStatusService.shared

    @State private var showingEditSheet = false
    @State private var selectedSection: ExpeditionSection = .overview

    var body: some View {
        List {
            // Overview Section
            Section {
                NavigationLink(value: ExpeditionSection.overview) {
                    SectionRow(
                        title: "Overview",
                        icon: "info.circle",
                        color: .blue,
                        detail: expedition.status.rawValue
                    )
                }
            }

            // Itinerary Section
            Section {
                NavigationLink(value: ExpeditionSection.itinerary) {
                    SectionRow(
                        title: "Itinerary",
                        icon: "calendar.day.timeline.left",
                        color: .orange,
                        detail: "\((expedition.itinerary ?? []).count) days"
                    )
                }
            }

            // Logistics Section
            Section {
                NavigationLink(value: ExpeditionSection.participants) {
                    SectionRow(
                        title: "Participants",
                        icon: "person.2",
                        color: .purple,
                        detail: "\((expedition.participants ?? []).count) people"
                    )
                }

                NavigationLink(value: ExpeditionSection.contacts) {
                    SectionRow(
                        title: "Contacts",
                        icon: "person.crop.rectangle.stack",
                        color: .teal,
                        detail: "\((expedition.contacts ?? []).count) contacts"
                    )
                }

                NavigationLink(value: ExpeditionSection.resupply) {
                    SectionRow(
                        title: "Resupply Points",
                        icon: "shippingbox",
                        color: .brown,
                        detail: "\((expedition.resupplyPoints ?? []).count) points"
                    )
                }

                NavigationLink(value: ExpeditionSection.permits) {
                    SectionRow(
                        title: "Permits",
                        icon: "doc.text",
                        color: .gray,
                        detail: "\((expedition.permits ?? []).count) permits"
                    )
                }
            } header: {
                Text("Logistics")
            }

            // Gear Section
            Section {
                NavigationLink(value: ExpeditionSection.gear) {
                    SectionRow(
                        title: "Gear List",
                        icon: "backpack",
                        color: .green,
                        detail: "\((expedition.gearItems ?? []).count) items"
                    )
                }
            }

            // Budget Section
            Section {
                NavigationLink(value: ExpeditionSection.budget) {
                    SectionRow(
                        title: "Budget",
                        icon: "dollarsign.circle",
                        color: .green,
                        detail: formatBudget()
                    )
                }
            }

            // Safety Section
            Section {
                NavigationLink(value: ExpeditionSection.safety) {
                    SectionRow(
                        title: "Risk Assessment",
                        icon: "exclamationmark.shield",
                        color: .red,
                        detail: "\((expedition.riskAssessments ?? []).count) risks"
                    )
                }
            } header: {
                Text("Safety")
            }
        }
        .navigationTitle(expedition.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: ExpeditionSection.self) { section in
            sectionView(for: section)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SyncStatusIndicator(syncService: syncService)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExpeditionFormView(mode: .edit(expedition))
        }
    }

    private func formatBudget() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: expedition.totalBudget)) ?? "$0"
    }

    @ViewBuilder
    private func sectionView(for section: ExpeditionSection) -> some View {
        switch section {
        case .overview:
            ExpeditionOverviewView(expedition: expedition)
        case .itinerary:
            ItineraryPlaceholderView(expedition: expedition)
        case .participants:
            ParticipantsPlaceholderView(expedition: expedition)
        case .contacts:
            ContactsPlaceholderView(expedition: expedition)
        case .resupply:
            ResupplyPlaceholderView(expedition: expedition)
        case .permits:
            PermitsPlaceholderView(expedition: expedition)
        case .gear:
            GearPlaceholderView(expedition: expedition)
        case .budget:
            BudgetPlaceholderView(expedition: expedition)
        case .safety:
            SafetyPlaceholderView(expedition: expedition)
        }
    }
}

// MARK: - Expedition Section

enum ExpeditionSection: Hashable {
    case overview
    case itinerary
    case participants
    case contacts
    case resupply
    case permits
    case gear
    case budget
    case safety
}

// MARK: - Section Row

struct SectionRow: View {
    let title: String
    let icon: String
    let color: Color
    let detail: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(title)
                .font(.body)

            Spacer()

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Overview View

struct ExpeditionOverviewView: View {
    @Bindable var expedition: Expedition

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Status", value: expedition.status.rawValue)

                if !expedition.location.isEmpty {
                    LabeledContent("Location", value: expedition.location)
                }

                if let startDate = expedition.startDate {
                    LabeledContent("Start Date") {
                        Text(startDate.formatted(date: .long, time: .omitted))
                    }
                }

                if let endDate = expedition.endDate {
                    LabeledContent("End Date") {
                        Text(endDate.formatted(date: .long, time: .omitted))
                    }
                }

                if expedition.totalDays > 0 {
                    LabeledContent("Duration", value: "\(expedition.totalDays) days")
                }
            }

            if !expedition.expeditionDescription.isEmpty {
                Section("Description") {
                    Text(expedition.expeditionDescription)
                }
            }

            if !expedition.notes.isEmpty {
                Section("Notes") {
                    Text(expedition.notes)
                }
            }

            Section("Summary") {
                LabeledContent("Participants", value: "\(expedition.participantCount)")
                LabeledContent("Itinerary Days", value: "\((expedition.itinerary ?? []).count)")
                LabeledContent("Gear Items", value: "\((expedition.gearItems ?? []).count)")
                LabeledContent("Budget Items", value: "\((expedition.budgetItems ?? []).count)")
            }
        }
        .navigationTitle("Overview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Placeholder Views for Phase 2+

struct ItineraryPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Itinerary",
            systemImage: "calendar.day.timeline.left",
            description: Text("Itinerary management coming in Phase 2")
        )
        .navigationTitle("Itinerary")
    }
}

struct ParticipantsPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Participants",
            systemImage: "person.2",
            description: Text("Participant management coming in Phase 4")
        )
        .navigationTitle("Participants")
    }
}

struct ContactsPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Contacts",
            systemImage: "person.crop.rectangle.stack",
            description: Text("Contact directory coming in Phase 4")
        )
        .navigationTitle("Contacts")
    }
}

struct ResupplyPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Resupply Points",
            systemImage: "shippingbox",
            description: Text("Resupply point management coming in Phase 4")
        )
        .navigationTitle("Resupply Points")
    }
}

struct PermitsPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Permits",
            systemImage: "doc.text",
            description: Text("Permit tracking coming in Phase 4")
        )
        .navigationTitle("Permits")
    }
}

struct GearPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Gear List",
            systemImage: "backpack",
            description: Text("Gear management coming in Phase 3")
        )
        .navigationTitle("Gear")
    }
}

struct BudgetPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Budget",
            systemImage: "dollarsign.circle",
            description: Text("Budget tracking coming in Phase 5")
        )
        .navigationTitle("Budget")
    }
}

struct SafetyPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Risk Assessment",
            systemImage: "exclamationmark.shield",
            description: Text("Risk assessment coming in Phase 4")
        )
        .navigationTitle("Safety")
    }
}

#Preview {
    NavigationStack {
        ExpeditionDetailView(expedition: Expedition(name: "Alaska 2026", location: "Brooks Range, AK"))
    }
    .modelContainer(for: Expedition.self, inMemory: true)
}
