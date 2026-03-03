import SwiftUI
import SwiftData

// swiftlint:disable file_length
struct ExpeditionDetailView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @ObservedObject private var syncService = SyncStatusService.shared

    @State private var showingEditSheet = false
    @State private var showingCSVImport = false
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

                NavigationLink(value: ExpeditionSection.routeSegments) {
                    SectionRow(
                        title: "Route Segments",
                        icon: "point.topleft.down.to.point.bottomright.curvepath",
                        color: .indigo,
                        detail: routeSegmentsDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.waterSources) {
                    SectionRow(
                        title: "Water Sources",
                        icon: "drop.fill",
                        color: .cyan,
                        detail: waterSourcesDetail
                    )
                }
            }

            // Planning Section
            Section {
                NavigationLink(value: ExpeditionSection.mealPlanning) {
                    SectionRow(
                        title: "Meal Planning",
                        icon: "fork.knife",
                        color: .orange,
                        detail: mealPlanningDetail
                    )
                }
            } header: {
                Text("Planning")
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

                NavigationLink(value: ExpeditionSection.transport) {
                    SectionRow(
                        title: "Transport",
                        icon: "airplane",
                        color: .blue,
                        detail: transportDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.accommodations) {
                    SectionRow(
                        title: "Accommodations",
                        icon: "building.2",
                        color: .purple,
                        detail: accommodationsDetail
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

                NavigationLink(value: ExpeditionSection.travelDocuments) {
                    SectionRow(
                        title: "Travel Documents",
                        icon: "book.closed",
                        color: .indigo,
                        detail: travelDocumentsDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.satelliteDevices) {
                    SectionRow(
                        title: "Satellite Devices",
                        icon: "antenna.radiowaves.left.and.right",
                        color: .orange,
                        detail: satelliteDevicesDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.checklist) {
                    SectionRow(
                        title: "Pre-Departure Tasks",
                        icon: "checklist",
                        color: .mint,
                        detail: checklistDetail
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
                        detail: riskAssessmentDetail
                    )
                }

                NavigationLink(value: ExpeditionSection.emergencyContacts) {
                    SectionRow(
                        title: "Emergency Contacts",
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        detail: emergencyContactsDetail
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

                NavigationLink(value: ExpeditionSection.escapeRoutes) {
                    SectionRow(
                        title: "Escape Routes",
                        icon: "arrow.uturn.backward.circle",
                        color: .orange,
                        detail: escapeRoutesDetail
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
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Expedition", systemImage: "pencil")
                    }

                    Button {
                        showingCSVImport = true
                    } label: {
                        Label("Import CSV", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExpeditionFormView(mode: .edit(expedition))
        }
        .sheet(isPresented: $showingCSVImport) {
            CSVImportView(expedition: expedition)
        }
    }

    private func formatBudget() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: expedition.totalBudget)) ?? "$0"
    }

    private var routeMapDetail: String {
        let count = RouteService.extractWaypoints(from: expedition).count
        return count == 0 ? "No waypoints" : count == 1 ? "1 waypoint" : "\(count) waypoints"
    }

    private var insuranceDetail: String {
        let count = (expedition.insurancePolicies ?? []).count
        return count == 0 ? "No policies" : count == 1 ? "1 policy" : "\(count) policies"
    }
    private var riskAssessmentDetail: String {
        let assessments = expedition.riskAssessments ?? []
        guard !assessments.isEmpty else { return "No risks" }
        let attention = assessments.filter { $0.needsAttention }.count
        return attention > 0 ? "\(assessments.count) risks, \(attention) need attention" : "\(assessments.count) risks"
    }
    private var emergencyContactsDetail: String {
        let count = (expedition.contacts ?? []).filter { $0.isEmergencyContact }.count
        return count == 0 ? "None set" : count == 1 ? "1 contact" : "\(count) contacts"
    }
    private var transportDetail: String {
        let count = (expedition.transportLegs ?? []).count
        return count == 0 ? "No transport" : count == 1 ? "1 leg" : "\(count) legs"
    }
    private var accommodationsDetail: String {
        let count = (expedition.accommodations ?? []).count
        return count == 0 ? "No accommodations" : count == 1 ? "1 accommodation" : "\(count) accommodations"
    }
    private var checklistDetail: String {
        let items = expedition.checklistItems ?? []
        guard !items.isEmpty else { return "No tasks" }
        return "\(items.filter { $0.isComplete }.count)/\(items.count) done"
    }
    private var escapeRoutesDetail: String {
        let routes = expedition.escapeRoutes ?? []
        guard !routes.isEmpty else { return "No routes" }
        let unverified = routes.filter { !$0.isVerified }.count
        return unverified > 0 ? "\(routes.count) routes, \(unverified) unverified" : "\(routes.count) routes"
    }
    private var routeSegmentsDetail: String {
        let count = (expedition.routeSegments ?? []).count
        return count == 0 ? "No segments" : count == 1 ? "1 segment" : "\(count) segments"
    }
    private var waterSourcesDetail: String {
        let count = (expedition.waterSources ?? []).count
        return count == 0 ? "No sources" : count == 1 ? "1 source" : "\(count) sources"
    }
    private var travelDocumentsDetail: String {
        let docs = expedition.travelDocuments ?? []
        guard !docs.isEmpty else { return "No documents" }
        let actionNeeded = docs.filter { $0.isActionRequired }.count
        return actionNeeded > 0 ? "\(docs.count) documents, \(actionNeeded) action needed" : "\(docs.count) documents"
    }
    private var mealPlanningDetail: String {
        let count = (expedition.mealPlans ?? []).count
        return count == 0 ? "No days planned" : count == 1 ? "1 day planned" : "\(count) days planned"
    }
    private var satelliteDevicesDetail: String {
        let count = (expedition.satelliteDevices ?? []).count
        return count == 0 ? "No devices" : count == 1 ? "1 device" : "\(count) devices"
    }

    // swiftlint:disable cyclomatic_complexity
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
        case .transport:
            TransportListView(expedition: expedition)
        case .accommodations:
            AccommodationListView(expedition: expedition)
        case .resupply:
            ResupplyListView(expedition: expedition)
        case .permits:
            PermitListView(expedition: expedition)
        case .satelliteDevices:
            SatelliteDeviceListView(expedition: expedition)
        case .checklist:
            ChecklistListView(expedition: expedition)
        case .gear:
            GearListView(expedition: expedition)
        case .budget:
            BudgetListView(expedition: expedition)
        case .safety:
            RiskAssessmentListView(expedition: expedition)
        case .emergencyContacts:
            EmergencyContactsView(expedition: expedition)
        case .insurance:
            InsuranceListView(expedition: expedition)
        case .escapeRoutes:
            EscapeRouteListView(expedition: expedition)
        case .shelters:
            ShelterListView()
        case .routeSegments:
            RouteSegmentListView(expedition: expedition)
        case .waterSources:
            WaterSourceListView(expedition: expedition)
        case .travelDocuments:
            TravelDocumentListView(expedition: expedition)
        case .mealPlanning:
            MealPlanListView(expedition: expedition)
        }
    }
    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Expedition Section

enum ExpeditionSection: Hashable {
    case overview
    case itinerary
    case routeMap
    case shelters
    case participants
    case contacts
    case transport
    case accommodations
    case resupply
    case permits
    case satelliteDevices
    case checklist
    case gear
    case budget
    case safety
    case emergencyContacts
    case insurance
    case escapeRoutes
    case routeSegments
    case waterSources
    case travelDocuments
    case mealPlanning
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

#Preview {
    NavigationStack {
        ExpeditionDetailView(expedition: Expedition(name: "Alaska 2026", location: "Brooks Range, AK"))
    }
    .modelContainer(for: Expedition.self, inMemory: true)
}
