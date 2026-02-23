import Foundation
import WeatherKit
import CoreLocation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "WeatherService")

/// Service for fetching and caching weather data using WeatherKit
@Observable
final class WeatherService {
    private let weatherService = WeatherKit.WeatherService.shared
    private var modelContext: ModelContext?

    // Cache duration in seconds (1 hour for forecasts)
    private let forecastCacheDuration: TimeInterval = 3600

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Weather

    /// Fetch weather forecast for a specific location and date
    func fetchForecast(
        latitude: Double,
        longitude: Double,
        locationName: String,
        forDate date: Date,
        itineraryDayId: UUID? = nil
    ) async throws -> WeatherForecast {
        // Check cache first
        if let cached = fetchCachedForecast(
            latitude: latitude,
            longitude: longitude,
            forDate: date
        ) {
            logger.debug("Using cached forecast for \(locationName)")
            return cached
        }

        // Fetch from WeatherKit
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let weather = try await weatherService.weather(for: location)

            // Find forecast for specific date
            let forecast = createForecast(
                from: weather,
                latitude: latitude,
                longitude: longitude,
                locationName: locationName,
                forDate: date,
                itineraryDayId: itineraryDayId
            )

            // Cache the forecast
            if let context = modelContext {
                context.insert(forecast)
                try context.save()
            }

            return forecast
        } catch {
            logger.error("Failed to fetch weather: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch weather for multiple days (itinerary)
    func fetchForecasts(
        for days: [ItineraryDay]
    ) async throws -> [UUID: WeatherForecast] {
        var results: [UUID: WeatherForecast] = [:]

        for day in days {
            guard let lat = day.endLatitude ?? day.startLatitude,
                  let lon = day.endLongitude ?? day.startLongitude,
                  let date = day.date else {
                continue
            }

            let locationName = day.endLocation.isEmpty ? day.startLocation : day.endLocation

            do {
                let forecast = try await fetchForecast(
                    latitude: lat,
                    longitude: lon,
                    locationName: locationName,
                    forDate: date,
                    itineraryDayId: day.id
                )
                results[day.id] = forecast
            } catch {
                logger.warning("Skipping weather for day \(day.dayNumber): \(error.localizedDescription)")
            }
        }

        return results
    }

    // MARK: - Cache Management

    private func fetchCachedForecast(
        latitude: Double,
        longitude: Double,
        forDate date: Date
    ) -> WeatherForecast? {
        guard let context = modelContext else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let descriptor = FetchDescriptor<WeatherForecast>(
            predicate: #Predicate { forecast in
                forecast.forecastDate >= startOfDay &&
                forecast.forecastDate < endOfDay &&
                !forecast.isExpired
            }
        )

        do {
            let forecasts = try context.fetch(descriptor)
            // Find one close to requested location
            return forecasts.first { forecast in
                let distance = sqrt(
                    pow(forecast.latitude - latitude, 2) +
                    pow(forecast.longitude - longitude, 2)
                )
                return distance < 0.1 // ~10km tolerance
            }
        } catch {
            return nil
        }
    }

    func clearExpiredCache() {
        guard let context = modelContext else { return }

        let now = Date()
        let descriptor = FetchDescriptor<WeatherForecast>(
            predicate: #Predicate { forecast in
                forecast.expiresAt < now
            }
        )

        do {
            let expired = try context.fetch(descriptor)
            for forecast in expired {
                context.delete(forecast)
            }
            try context.save()
            logger.info("Cleared \(expired.count) expired forecasts")
        } catch {
            logger.error("Failed to clear cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func createForecast(
        from weather: Weather,
        latitude: Double,
        longitude: Double,
        locationName: String,
        forDate date: Date,
        itineraryDayId: UUID?
    ) -> WeatherForecast {
        let forecast = WeatherForecast(
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            forecastDate: date
        )

        // Find the day forecast closest to the target date
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        if let dayForecast = weather.dailyForecast.forecast.first(where: { dayWeather in
            calendar.startOfDay(for: dayWeather.date) == targetDay
        }) {
            forecast.conditionCode = dayForecast.condition.rawValue
            forecast.conditionDescription = dayForecast.condition.description
            forecast.temperatureHighCelsius = dayForecast.highTemperature.converted(to: .celsius).value
            forecast.temperatureLowCelsius = dayForecast.lowTemperature.converted(to: .celsius).value
            forecast.precipitationChance = dayForecast.precipitationChance
            forecast.uvIndex = dayForecast.uvIndex.value
            forecast.sunriseTime = dayForecast.sun.sunrise
            forecast.sunsetTime = dayForecast.sun.sunset
            forecast.windSpeedKmh = dayForecast.wind.speed.converted(to: .kilometersPerHour).value

            // Extract moon phase
            forecast.moonPhase = dayForecast.moon.phase.rawValue
            // Calculate moon illumination from phase
            forecast.moonIllumination = moonIllumination(for: dayForecast.moon.phase)
        } else {
            // Use current weather as fallback
            let current = weather.currentWeather
            forecast.conditionCode = current.condition.rawValue
            forecast.conditionDescription = current.condition.description
            forecast.temperatureHighCelsius = current.temperature.converted(to: .celsius).value
            forecast.temperatureLowCelsius = current.apparentTemperature.converted(to: .celsius).value
            forecast.humidity = current.humidity
            forecast.uvIndex = current.uvIndex.value
            forecast.windSpeedKmh = current.wind.speed.converted(to: .kilometersPerHour).value
            forecast.windDirection = current.wind.compassDirection.abbreviation
            forecast.visibility = current.visibility.converted(to: .kilometers).value
            forecast.pressure = current.pressure.converted(to: .hectopascals).value
        }

        // Extract weather alerts if available
        if let alerts = weather.weatherAlerts, let firstAlert = alerts.first {
            forecast.alertType = firstAlert.summary
            forecast.alertSeverity = firstAlert.severity.rawValue
            forecast.alertDescription = firstAlert.detailsURL.absoluteString
            // WeatherAlert doesn't expose start/end dates directly in the API
            // The metadata is available through the detailsURL
        }

        forecast.itineraryDayId = itineraryDayId
        forecast.fetchedAt = Date()
        forecast.expiresAt = Date().addingTimeInterval(forecastCacheDuration)
        forecast.dataSource = "WeatherKit"

        return forecast
    }

    /// Calculate approximate moon illumination from phase
    private func moonIllumination(for phase: MoonPhase) -> Double {
        switch phase {
        case .new:
            return 0.0
        case .waxingCrescent:
            return 0.25
        case .firstQuarter:
            return 0.5
        case .waxingGibbous:
            return 0.75
        case .full:
            return 1.0
        case .waningGibbous:
            return 0.75
        case .lastQuarter:
            return 0.5
        case .waningCrescent:
            return 0.25
        @unknown default:
            return 0.5
        }
    }

    // MARK: - Static Formatting

    static func formatTemperature(_ celsius: Double?, includeUnit: Bool = true) -> String {
        guard let temp = celsius else { return "N/A" }
        let measurement = Measurement(value: temp, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = includeUnit ? .providedUnit : .temperatureWithoutUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: measurement)
    }

    static func formatPrecipitationChance(_ chance: Double?) -> String {
        guard let chance = chance else { return "N/A" }
        return "\(Int(chance * 100))%"
    }

    static func formatWindSpeed(_ kmh: Double?) -> String {
        guard let speed = kmh else { return "N/A" }
        let measurement = Measurement(value: speed, unit: UnitSpeed.kilometersPerHour)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: measurement)
    }

    static func conditionIcon(for code: String) -> String {
        switch code.lowercased() {
        case "clear", "sunny", "mostlyclear":
            return "sun.max.fill"
        case "partlycloudy", "mostlycloudy":
            return "cloud.sun.fill"
        case "cloudy", "overcast":
            return "cloud.fill"
        case "rain", "drizzle", "showers", "heavyrain":
            return "cloud.rain.fill"
        case "thunderstorm", "thunderstorms", "scatteredthunderstorms":
            return "cloud.bolt.rain.fill"
        case "snow", "flurries", "heavysnow":
            return "cloud.snow.fill"
        case "sleet", "freezingrain", "freezingdrizzle":
            return "cloud.sleet.fill"
        case "fog", "mist", "haze", "smoky":
            return "cloud.fog.fill"
        case "wind", "windy", "breezy":
            return "wind"
        case "blizzard":
            return "wind.snow"
        case "blowingsnow":
            return "wind.snow"
        case "hot":
            return "sun.max.fill"
        case "frigid":
            return "thermometer.snowflake"
        default:
            return "cloud.fill"
        }
    }
}
