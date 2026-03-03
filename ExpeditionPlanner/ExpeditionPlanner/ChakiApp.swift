import SwiftUI
import SwiftData
import CloudKit
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "App")

@main
struct ChakiApp: App {
    let modelContainer: ModelContainer

    init() {
        // Ensure Application Support directory exists before SwiftData initializes
        // to avoid noisy CoreData recovery errors on first launch
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
           !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        do {
            let schema = Schema([
                Expedition.self,
                ItineraryDay.self,
                GearItem.self,
                Participant.self,
                Contact.self,
                ResupplyPoint.self,
                Permit.self,
                BudgetItem.self,
                RiskAssessment.self,
                InsurancePolicy.self,
                Shelter.self,
                HistoricalClimate.self,
                ChecklistItem.self,
                EscapeRoute.self,
                EscapeWaypoint.self,
                RouteSegment.self,
                WaterSource.self,
                TravelDocument.self,
                MealPlan.self,
                Meal.self
            ])

            let cloudKitDatabase: ModelConfiguration.CloudKitDatabase
            if FileManager.default.ubiquityIdentityToken != nil {
                cloudKitDatabase = .automatic
                logger.info("iCloud account available — enabling CloudKit sync")
            } else {
                cloudKitDatabase = .none
                logger.info("No iCloud account — using local-only storage")
            }

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: cloudKitDatabase
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await rescheduleNotifications() }
            }
        }
    }

    @MainActor
    private func rescheduleNotifications() async {
        let context = modelContainer.mainContext
        do {
            let descriptor = FetchDescriptor<Expedition>()
            let expeditions = try context.fetch(descriptor)
            await NotificationService.shared.scheduleAllNotifications(for: expeditions)
            await NotificationService.shared.updateBadgeCount(for: expeditions)
        } catch {
            logger.error("Failed to reschedule notifications: \(error.localizedDescription)")
        }
    }
}
