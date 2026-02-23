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

                NavigationLink(value: ExpeditionSection.routeMap) {
                    SectionRow(
                        title: "Route Map",
                        icon: "map",
                        color: .cyan,
                        detail: routeMapDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.shelters) {
                    SectionRow(
                        title: "Shelters & Cabins",
                        icon: "house.fill",
                        color: .brown,
                        detail: "Database"
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

                NavigationLink(value: ExpeditionSection.insurance) {
                    SectionRow(
                        title: "Insurance",
                        icon: "shield.checkered",
                        color: .blue,
                        detail: insuranceDetail
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

    private var routeMapDetail: String {
        let waypoints = RouteService.extractWaypoints(from: expedition)
        let waypointCount = waypoints.count
        if waypointCount == 0 {
            return "No waypoints"
        } else if waypointCount == 1 {
            return "1 waypoint"
        } else {
            return "\(waypointCount) waypoints"
        }
    }

    private var insuranceDetail: String {
        let count = (expedition.insurancePolicies ?? []).count
        if count == 0 {
            return "No policies"
        } else if count == 1 {
            return "1 policy"
        } else {
            return "\(count) policies"
        }
    }

    @ViewBuilder
    private func sectionView(for section: ExpeditionSection) -> some View {
        switch section {
        case .overview:
            ExpeditionOverviewView(expedition: expedition)
        case .itinerary:
            ItineraryView(expedition: expedition)
        case .routeMap:
            RouteMapView(expedition: expedition)
        case .participants:
            ParticipantListView(expedition: expedition)
        case .contacts:
            ContactListView(expedition: expedition)
        case .resupply:
            ResupplyListView(expedition: expedition)
        case .permits:
            PermitListView(expedition: expedition)
        case .gear:
            GearListView(expedition: expedition)
        case .budget:
            BudgetListView(expedition: expedition)
        case .safety:
            SafetyPlaceholderView(expedition: expedition)
        case .insurance:
            InsuranceListView(expedition: expedition)
        case .shelters:
            ShelterListView()
        }
    }
}

// MARK: - Expedition Section

enum ExpeditionSection: Hashable {
    case overview
    case itinerary
    case routeMap
    case shelters
    case participants
    case contacts
    case resupply
    case permits
    case gear
    case budget
    case safety
    case insurance
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

// MARK: - Placeholder Views

struct SafetyPlaceholderView: View {
    let expedition: Expedition

    var body: some View {
        ContentUnavailableView(
            "Risk Assessment",
            systemImage: "exclamationmark.shield",
            description: Text("Risk assessment management coming soon")
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
