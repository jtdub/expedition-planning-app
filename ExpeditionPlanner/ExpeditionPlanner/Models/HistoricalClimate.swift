import Foundation
import SwiftData

@Model
final class HistoricalClimate {
    var id: UUID = UUID()
    var latitude: Double = 0
    var longitude: Double = 0
    var locationName: String = ""
    var month: Int = 1 // 1-12

    // Temperature averages (Celsius)
    var avgHighCelsius: Double?
    var avgLowCelsius: Double?
    var recordHighCelsius: Double?
    var recordLowCelsius: Double?

    // Precipitation averages
    var avgPrecipitationMm: Double?
    var avgSnowfallCm: Double?
    var avgRainyDays: Double?
    var avgSnowyDays: Double?

    // Wind averages
    var avgWindSpeedKmh: Double?
    var prevailingWindDirection: String?

    // Daylight
    var avgDaylightHours: Double?
    var avgSunshineHours: Double?

    // Other
    var avgHumidity: Double?
    var avgCloudCover: Double?

    // Planning notes
    var seasonNotes: String = ""
    var hazardNotes: String = ""

    // Cache metadata
    var dataSource: String = ""
    var lastUpdated: Date = Date()

    init(
        latitude: Double = 0,
        longitude: Double = 0,
        locationName: String = "",
        month: Int = 1
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.month = month
        self.lastUpdated = Date()
    }

    // MARK: - Computed Properties

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.day = 1
        components.year = 2024
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    var avgHigh: Measurement<UnitTemperature>? {
        guard let celsius = avgHighCelsius else { return nil }
        return Measurement(value: celsius, unit: .celsius)
    }

    var avgLow: Measurement<UnitTemperature>? {
        guard let celsius = avgLowCelsius else { return nil }
        return Measurement(value: celsius, unit: .celsius)
    }

    var temperatureRangeText: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0

        if let high = avgHigh, let low = avgLow {
            return "\(formatter.string(from: low)) to \(formatter.string(from: high))"
        }
        return "N/A"
    }

    var avgPrecipitation: Measurement<UnitLength>? {
        guard let mm = avgPrecipitationMm else { return nil }
        return Measurement(value: mm, unit: .millimeters)
    }

    var avgSnowfall: Measurement<UnitLength>? {
        guard let cm = avgSnowfallCm else { return nil }
        return Measurement(value: cm, unit: .centimeters)
    }

    var avgWindSpeed: Measurement<UnitSpeed>? {
        guard let kmh = avgWindSpeedKmh else { return nil }
        return Measurement(value: kmh, unit: .kilometersPerHour)
    }

    var seasonCategory: SeasonCategory {
        // Categorize based on temperature
        guard let high = avgHighCelsius else { return .unknown }

        switch high {
        case ..<(-10): return .extremeCold
        case (-10)..<0: return .cold
        case 0..<10: return .cool
        case 10..<20: return .mild
        case 20..<30: return .warm
        default: return .hot
        }
    }

    var precipitationCategory: PrecipitationCategory {
        guard let mm = avgPrecipitationMm else { return .unknown }

        switch mm {
        case ..<25: return .dry
        case 25..<75: return .moderate
        case 75..<150: return .wet
        default: return .veryWet
        }
    }
}

// MARK: - Season Category

enum SeasonCategory: String, Codable {
    case extremeCold = "Extreme Cold"
    case cold = "Cold"
    case cool = "Cool"
    case mild = "Mild"
    case warm = "Warm"
    case hot = "Hot"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .extremeCold: return "thermometer.snowflake"
        case .cold: return "snowflake"
        case .cool: return "thermometer.low"
        case .mild: return "thermometer.medium"
        case .warm: return "sun.max"
        case .hot: return "sun.max.fill"
        case .unknown: return "questionmark"
        }
    }

    var color: String {
        switch self {
        case .extremeCold: return "purple"
        case .cold: return "blue"
        case .cool: return "teal"
        case .mild: return "green"
        case .warm: return "orange"
        case .hot: return "red"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Precipitation Category

enum PrecipitationCategory: String, Codable {
    case dry = "Dry"
    case moderate = "Moderate"
    case wet = "Wet"
    case veryWet = "Very Wet"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .dry: return "sun.max"
        case .moderate: return "cloud.drizzle"
        case .wet: return "cloud.rain"
        case .veryWet: return "cloud.heavyrain"
        case .unknown: return "questionmark"
        }
    }
}
