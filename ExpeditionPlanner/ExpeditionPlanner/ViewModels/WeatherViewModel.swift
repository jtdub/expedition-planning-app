import Foundation
import SwiftData
import CoreLocation

@Observable
final class WeatherViewModel {
    private var modelContext: ModelContext
    private let weatherService: WeatherService

    var forecasts: [UUID: WeatherForecast] = [:]
    var isLoading = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.weatherService = WeatherService(modelContext: modelContext)
    }

    // MARK: - Loading

    func loadForecasts(for days: [ItineraryDay]) async {
        isLoading = true
        errorMessage = nil

        do {
            forecasts = try await weatherService.fetchForecasts(for: days)
            isLoading = false
        } catch {
            errorMessage = "Failed to load weather: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func loadForecast(for day: ItineraryDay) async {
        guard let lat = day.endLatitude ?? day.startLatitude,
              let lon = day.endLongitude ?? day.startLongitude,
              let date = day.date else {
            return
        }

        isLoading = true
        errorMessage = nil

        let locationName = day.endLocation.isEmpty ? day.startLocation : day.endLocation

        do {
            let forecast = try await weatherService.fetchForecast(
                latitude: lat,
                longitude: lon,
                locationName: locationName,
                forDate: date,
                itineraryDayId: day.id
            )
            forecasts[day.id] = forecast
            isLoading = false
        } catch {
            errorMessage = "Failed to load weather: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Accessors

    func forecast(for dayId: UUID) -> WeatherForecast? {
        forecasts[dayId]
    }

    func hasForecast(for dayId: UUID) -> Bool {
        forecasts[dayId] != nil
    }

    // MARK: - Cache

    func clearCache() {
        weatherService.clearExpiredCache()
    }
}
