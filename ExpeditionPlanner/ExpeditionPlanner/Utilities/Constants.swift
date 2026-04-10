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

    // URLs
    // swiftlint:disable force_unwrapping
    static let supportURL = URL(string: "https://www.jtdub.com/apps/support/expedition-planning/")!
    static let privacyPolicyURL = URL(string: "https://www.jtdub.com/apps/privacy/expedition-planning/")!
    // swiftlint:enable force_unwrapping
}

enum NotificationIdentifiers {
    static let permitDeadline = "permit.deadline"
    static let permitExpiry = "permit.expiry"
    static let checkIn = "checkin.reminder"
    static let departureReminder = "departure.reminder"
    static let transportDeparture = "transport.departure"
    static let accommodationCheckIn = "accommodation.checkin"
    static let documentExpiry = "document.expiry"
    static let checklistDue = "checklist.due"
    static let insuranceExpiry = "insurance.expiry"
    static let deviceSubscription = "device.subscription"
    static let deviceReturn = "device.return"
    static let expeditionDeparture = "expedition.departure"
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
