import SwiftUI
import SwiftData
import CloudKit
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "App")

@main
struct ChakiApp: App {
    let modelContainer: ModelContainer

    init() {
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
                HistoricalClimate.self
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
