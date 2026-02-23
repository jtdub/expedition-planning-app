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

    // Moon phase
    var moonPhase: String?
    var moonIllumination: Double?

    // Severe weather alerts
    var alertType: String?
    var alertSeverity: String?
    var alertDescription: String?
    var alertStartTime: Date?
    var alertEndTime: Date?

    // Air quality
    var airQualityIndex: Int?
    var airQualityCategory: String?
    var primaryPollutant: String?

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

    var moonPhaseIcon: String {
        guard let phase = moonPhase?.lowercased() else { return "moon" }
        switch phase {
        case "new", "newmoon":
            return "moon.fill"
        case "waxingcrescent":
            return "moon.zzz"
        case "firstquarter":
            return "moon.haze"
        case "waxinggibbous":
            return "moon.stars"
        case "full", "fullmoon":
            return "moon.circle.fill"
        case "waninggibbous":
            return "moon.stars.fill"
        case "lastquarter", "thirdquarter":
            return "moon.haze.fill"
        case "waningcrescent":
            return "moon.zzz.fill"
        default:
            return "moon"
        }
    }

    var hasWeatherAlert: Bool {
        guard let type = alertType else { return false }
        return !type.isEmpty
    }

    var alertSeverityLevel: AlertSeverity {
        guard let severity = alertSeverity?.lowercased() else { return .unknown }
        switch severity {
        case "extreme": return .extreme
        case "severe": return .severe
        case "moderate": return .moderate
        case "minor": return .minor
        default: return .unknown
        }
    }

    var airQualityLevel: AirQualityLevel {
        guard let aqi = airQualityIndex else { return .unknown }
        switch aqi {
        case 0...50: return .good
        case 51...100: return .moderate
        case 101...150: return .unhealthySensitive
        case 151...200: return .unhealthy
        case 201...300: return .veryUnhealthy
        default: return .hazardous
        }
    }
}

// MARK: - Alert Severity

enum AlertSeverity: String, Codable {
    case extreme = "Extreme"
    case severe = "Severe"
    case moderate = "Moderate"
    case minor = "Minor"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .extreme: return "exclamationmark.triangle.fill"
        case .severe: return "exclamationmark.triangle.fill"
        case .moderate: return "exclamationmark.triangle"
        case .minor: return "info.circle"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .extreme: return "red"
        case .severe: return "orange"
        case .moderate: return "yellow"
        case .minor: return "blue"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Air Quality Level

enum AirQualityLevel: String, Codable {
    case good = "Good"
    case moderate = "Moderate"
    case unhealthySensitive = "Unhealthy for Sensitive Groups"
    case unhealthy = "Unhealthy"
    case veryUnhealthy = "Very Unhealthy"
    case hazardous = "Hazardous"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .good: return "aqi.low"
        case .moderate: return "aqi.medium"
        case .unhealthySensitive, .unhealthy: return "aqi.high"
        case .veryUnhealthy, .hazardous: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .good: return "green"
        case .moderate: return "yellow"
        case .unhealthySensitive: return "orange"
        case .unhealthy: return "red"
        case .veryUnhealthy: return "purple"
        case .hazardous: return "brown"
        case .unknown: return "gray"
        }
    }
}
