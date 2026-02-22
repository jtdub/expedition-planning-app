import Foundation
import SwiftUI

// MARK: - Measurement Formatters

extension Measurement where UnitType == UnitLength {
    func formatted(as unit: ElevationUnit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit

        switch unit {
        case .meters:
            let converted = self.converted(to: .meters)
            return formatter.string(from: converted)
        case .feet:
            let converted = self.converted(to: .feet)
            return formatter.string(from: converted)
        }
    }

    func formatted(as unit: DistanceUnit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit

        switch unit {
        case .kilometers:
            let converted = self.converted(to: .kilometers)
            return formatter.string(from: converted)
        case .miles:
            let converted = self.converted(to: .miles)
            return formatter.string(from: converted)
        }
    }
}

extension Measurement where UnitType == UnitMass {
    func formatted(as unit: WeightUnit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit

        switch unit {
        case .kilograms:
            let converted = self.converted(to: .kilograms)
            return formatter.string(from: converted)
        case .pounds:
            let converted = self.converted(to: .pounds)
            return formatter.string(from: converted)
        case .ounces:
            let converted = self.converted(to: .ounces)
            return formatter.string(from: converted)
        }
    }
}

extension Measurement where UnitType == UnitTemperature {
    func formatted(as unit: TemperatureUnit) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit

        switch unit {
        case .celsius:
            let converted = self.converted(to: .celsius)
            return formatter.string(from: converted)
        case .fahrenheit:
            let converted = self.converted(to: .fahrenheit)
            return formatter.string(from: converted)
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    func daysBetween(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self.startOfDay, to: other.startOfDay).day ?? 0
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

// MARK: - String Extensions

extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Array Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
