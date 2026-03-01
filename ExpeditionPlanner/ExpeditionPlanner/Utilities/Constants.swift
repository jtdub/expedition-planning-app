import Foundation

enum AppConstants {
    // CloudKit
    static let cloudKitContainerIdentifier = "iCloud.com.chaki.app"

    // Acclimatization
    static let maxSafeElevationGainPerDay: Double = 500 // meters
    static let altitudeThreshold: Double = 3000 // meters above which acclimatization applies

    // Weight
    static let recommendedBaseWeightKg: Double = 9.0 // ~20 lbs
    static let maxPackWeightKg: Double = 18.0 // ~40 lbs

    // Dates
    static let defaultExpeditionDuration: Int = 7 // days

    // UI
    static let maxRecentExpeditions: Int = 5
    static let searchDebounceInterval: TimeInterval = 0.3
}

enum NotificationIdentifiers {
    static let permitDeadline = "permit.deadline"
    static let checkIn = "checkin.reminder"
    static let departureReminder = "departure.reminder"
}

enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let lastSyncDate = "lastSyncDate"
    static let elevationUnit = "elevationUnit"
    static let weightUnit = "weightUnit"
    static let distanceUnit = "distanceUnit"
    static let temperatureUnit = "temperatureUnit"
    static let defaultCurrency = "defaultCurrency"
    static let colorScheme = "colorScheme"
    static let iCloudSyncEnabled = "iCloudSyncEnabled"
}
