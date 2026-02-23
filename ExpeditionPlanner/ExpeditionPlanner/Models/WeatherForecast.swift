import Foundation
import SwiftData

@Model
final class WeatherForecast {
    var id: UUID = UUID()
    var latitude: Double = 0
    var longitude: Double = 0
    var locationName: String = ""
    var forecastDate: Date = Date()

    // Weather conditions
    var conditionCode: String = ""
    var conditionDescription: String = ""
    var temperatureHighCelsius: Double?
    var temperatureLowCelsius: Double?
    var temperatureFeelsLikeCelsius: Double?

    // Precipitation
    var precipitationChance: Double?
    var precipitationAmountMm: Double?
    var precipitationType: String?
    var snowfallAmountCm: Double?

    // Wind
    var windSpeedKmh: Double?
    var windGustKmh: Double?
    var windDirection: String?

    // Other conditions
    var humidity: Double?
    var uvIndex: Int?
    var visibility: Double?
    var cloudCover: Double?
    var pressure: Double?

    // Sunrise/sunset
    var sunriseTime: Date?
    var sunsetTime: Date?

    // Cache metadata
    var fetchedAt: Date = Date()
    var expiresAt: Date = Date()
    var dataSource: String = "WeatherKit"

    // Link to itinerary day
    var itineraryDayId: UUID?

    init(
        latitude: Double = 0,
        longitude: Double = 0,
        locationName: String = "",
        forecastDate: Date = Date()
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.forecastDate = forecastDate
        self.fetchedAt = Date()
        self.expiresAt = Date().addingTimeInterval(3600) // 1 hour default
    }

    // MARK: - Computed Properties

    var isExpired: Bool {
        Date() > expiresAt
    }

    var temperatureHigh: Measurement<UnitTemperature>? {
        guard let celsius = temperatureHighCelsius else { return nil }
        return Measurement(value: celsius, unit: .celsius)
    }

    var temperatureLow: Measurement<UnitTemperature>? {
        guard let celsius = temperatureLowCelsius else { return nil }
        return Measurement(value: celsius, unit: .celsius)
    }

    var temperatureRange: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0

        if let high = temperatureHigh, let low = temperatureLow {
            return "\(formatter.string(from: low)) - \(formatter.string(from: high))"
        } else if let high = temperatureHigh {
            return "High: \(formatter.string(from: high))"
        } else if let low = temperatureLow {
            return "Low: \(formatter.string(from: low))"
        }
        return "N/A"
    }

    var windSpeed: Measurement<UnitSpeed>? {
        guard let kmh = windSpeedKmh else { return nil }
        return Measurement(value: kmh, unit: .kilometersPerHour)
    }

    var precipitationChanceText: String {
        guard let chance = precipitationChance else { return "N/A" }
        return "\(Int(chance * 100))%"
    }

    var conditionIcon: String {
        // Map common condition codes to SF Symbols
        switch conditionCode.lowercased() {
        case "clear", "sunny":
            return "sun.max.fill"
        case "partlycloudy", "mostlycloudy":
            return "cloud.sun.fill"
        case "cloudy", "overcast":
            return "cloud.fill"
        case "rain", "drizzle", "showers":
            return "cloud.rain.fill"
        case "thunderstorm", "storm":
            return "cloud.bolt.rain.fill"
        case "snow", "flurries":
            return "cloud.snow.fill"
        case "sleet", "freezingrain":
            return "cloud.sleet.fill"
        case "fog", "mist", "haze":
            return "cloud.fog.fill"
        case "wind", "windy":
            return "wind"
        case "blizzard":
            return "wind.snow"
        default:
            return "cloud.fill"
        }
    }

    var daylightHours: Double? {
        guard let sunrise = sunriseTime, let sunset = sunsetTime else { return nil }
        return sunset.timeIntervalSince(sunrise) / 3600
    }
}
