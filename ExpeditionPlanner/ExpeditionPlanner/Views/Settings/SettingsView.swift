import SwiftUI

struct SettingsView: View {
    // Unit preferences
    @AppStorage("elevationUnit")
    private var elevationUnit: ElevationUnit = .meters

    @AppStorage("weightUnit")
    private var weightUnit: WeightUnit = .kilograms

    @AppStorage("distanceUnit")
    private var distanceUnit: DistanceUnit = .kilometers

    @AppStorage("temperatureUnit")
    private var temperatureUnit: TemperatureUnit = .celsius

    // Currency
    @AppStorage("defaultCurrency")
    private var defaultCurrency: String = "USD"

    // Appearance
    @AppStorage("colorScheme")
    private var colorScheme: AppColorScheme = .system

    // Sync
    @AppStorage("iCloudSyncEnabled")
    private var iCloudSyncEnabled: Bool = true

    // Notifications
    @AppStorage("permitDeadlineNotifications")
    private var permitDeadlineNotifications: Bool = true

    @AppStorage("departureReminderNotifications")
    private var departureReminderNotifications: Bool = true

    @AppStorage("gearChecklistReminders")
    private var gearChecklistReminders: Bool = true

    @AppStorage("budgetAlertNotifications")
    private var budgetAlertNotifications: Bool = false

    @AppStorage("reminderDaysBefore")
    private var reminderDaysBefore: Int = 7

    // Export
    @AppStorage("defaultExportFormat")
    private var defaultExportFormat: ExportFormat = .pdf

    // Templates
    @AppStorage("defaultGearTemplate")
    private var defaultGearTemplate: GearTemplate = .backpacking

    private let githubURL = URL(string: "https://github.com/jtdub/expedition-planning-app")

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Elevation", selection: $elevationUnit) {
                        ForEach(ElevationUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }

                    Picker("Weight", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }

                    Picker("Distance", selection: $distanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }

                    Picker("Temperature", selection: $temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                }

                Section("Currency") {
                    Picker("Default Currency", selection: $defaultCurrency) {
                        ForEach(Currency.allCases, id: \.code) { currency in
                            Text("\(currency.code) - \(currency.name)").tag(currency.code)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $colorScheme) {
                        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.rawValue).tag(scheme)
                        }
                    }
                }

                Section {
                    Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                } header: {
                    Text("Sync")
                } footer: {
                    Text("When enabled, your expeditions sync across all your devices.")
                }

                Section {
                    Toggle("Permit Deadlines", isOn: $permitDeadlineNotifications)
                    Toggle("Departure Reminders", isOn: $departureReminderNotifications)
                    Toggle("Gear Checklist", isOn: $gearChecklistReminders)
                    Toggle("Budget Alerts", isOn: $budgetAlertNotifications)

                    Picker("Remind Me", selection: $reminderDaysBefore) {
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("7 days before").tag(7)
                        Text("14 days before").tag(14)
                        Text("30 days before").tag(30)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get notified about important expedition dates and deadlines.")
                }

                Section {
                    Picker("Default Template", selection: $defaultGearTemplate) {
                        ForEach(GearTemplate.allCases, id: \.self) { template in
                            Text(template.rawValue).tag(template)
                        }
                    }
                } header: {
                    Text("Gear Lists")
                } footer: {
                    Text("This template will be used when creating new expeditions.")
                }

                Section {
                    Picker("Default Format", selection: $defaultExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.rawValue, systemImage: format.icon).tag(format)
                        }
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Choose the default format for exporting expedition data.")
                }

                Section("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    LabeledContent("Build", value: Bundle.main.buildNumber)

                    if let url = githubURL {
                        Link(destination: url) {
                            Label("GitHub Repository", systemImage: "link")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @StateObject private var mapCache = MapCacheService.shared
    @State private var showingExportSheet = false
    @State private var showingClearConfirmation = false
    @State private var showingDownloadSheet = false

    var body: some View {
        List {
            Section {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    // Import action
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Import / Export")
            } footer: {
                Text("Export your expedition data for backup or transfer.")
            }

            // Offline Maps Section
            Section {
                LabeledContent("Cache Size", value: mapCache.formattedCacheSize)

                if mapCache.isDownloading {
                    HStack {
                        Text("Downloading...")
                        Spacer()
                        ProgressView(value: mapCache.downloadProgress)
                            .frame(width: 100)
                    }
                }

                ForEach(mapCache.cachedRegions) { region in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(region.name)
                            .font(.body)
                        HStack {
                            Text("\(region.tileCount) tiles")
                            Text("•")
                            Text(region.formattedSize)
                            Text("•")
                            Text("Zoom \(region.minZoom)-\(region.maxZoom)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            mapCache.deleteRegion(region)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear All Map Cache", systemImage: "trash")
                }
                .disabled(mapCache.cachedRegions.isEmpty)
            } header: {
                Text("Offline Maps")
            } footer: {
                Text(offlineMapsFooter)
            }
        }
        .navigationTitle("Data Management")
        .confirmationDialog("Clear Cache?", isPresented: $showingClearConfirmation) {
            Button("Clear Cache", role: .destructive) {
                mapCache.clearCache()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all downloaded offline map tiles.")
        }
    }

    private var offlineMapsFooter: String {
        if mapCache.cachedRegions.isEmpty {
            return "Download map regions from the Route Map view for offline use."
        } else {
            return "Swipe left on a region to delete it."
        }
    }
}

// MARK: - Unit Enums

enum ElevationUnit: String, CaseIterable {
    case meters = "Meters (m)"
    case feet = "Feet (ft)"
}

enum WeightUnit: String, CaseIterable {
    case kilograms = "Kilograms (kg)"
    case pounds = "Pounds (lb)"
    case ounces = "Ounces (oz)"
}

enum DistanceUnit: String, CaseIterable {
    case kilometers = "Kilometers (km)"
    case miles = "Miles (mi)"
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius (°C)"
    case fahrenheit = "Fahrenheit (°F)"
}

enum AppColorScheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case json = "JSON"

    var icon: String {
        switch self {
        case .pdf:
            return "doc.richtext"
        case .csv:
            return "tablecells"
        case .json:
            return "curlybraces"
        }
    }
}

enum GearTemplate: String, CaseIterable {
    case backpacking = "Backpacking"
    case mountaineering = "Mountaineering"
    case kayaking = "Kayaking/Packrafting"
    case skiing = "Ski Touring"
    case ultralight = "Ultralight"
    case expeditionHeavy = "Expedition (Heavy)"
    case custom = "Custom"
}

// MARK: - Currency

struct Currency: Hashable {
    let code: String
    let name: String

    static let allCases: [Self] = [
        Self(code: "USD", name: "US Dollar"),
        Self(code: "EUR", name: "Euro"),
        Self(code: "GBP", name: "British Pound"),
        Self(code: "CAD", name: "Canadian Dollar"),
        Self(code: "AUD", name: "Australian Dollar"),
        Self(code: "CHF", name: "Swiss Franc"),
        Self(code: "JPY", name: "Japanese Yen"),
        Self(code: "PEN", name: "Peruvian Sol"),
        Self(code: "MXN", name: "Mexican Peso"),
        Self(code: "NZD", name: "New Zealand Dollar"),
        Self(code: "NOK", name: "Norwegian Krone"),
        Self(code: "SEK", name: "Swedish Krona"),
        Self(code: "INR", name: "Indian Rupee"),
        Self(code: "CNY", name: "Chinese Yuan")
    ]
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView()
}
