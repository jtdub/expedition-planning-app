import SwiftUI
import SwiftData

@main
struct ExpeditionPlannerApp: App {
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
                WeatherForecast.self,
                HistoricalClimate.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
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
