import SwiftUI
import SwiftData

struct HistoricalClimateView: View {
    let locationName: String
    let latitude: Double
    let longitude: Double

    @Environment(\.modelContext)
    private var modelContext

    @State private var climateData: [HistoricalClimate] = []
    @State private var isLoading = false
    @State private var selectedMonth: Int?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading climate data...")
            } else if climateData.isEmpty {
                ContentUnavailableView {
                    Label("No Climate Data", systemImage: "thermometer.medium.slash")
                } description: {
                    Text("Historical climate data is not available for this location.")
                }
            } else {
                climateList
            }
        }
        .navigationTitle("Historical Climate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadClimateData()
        }
    }

    // MARK: - Climate List

    private var climateList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationName)
                        .font(.headline)
                    Text("Lat: \(latitude, specifier: "%.4f"), Lon: \(longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(climateData.sorted { $0.month < $1.month }) { climate in
                    ClimateMonthCard(climate: climate)
                        .onTapGesture {
                            selectedMonth = climate.month
                        }
                }
            } header: {
                Text("Monthly Averages")
            }

            if let selected = selectedMonth,
               let climate = climateData.first(where: { $0.month == selected }) {
                Section {
                    ClimateDetailSection(climate: climate)
                } header: {
                    Text("\(climate.monthName) Details")
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadClimateData() {
        isLoading = true

        let descriptor = FetchDescriptor<HistoricalClimate>(
            predicate: #Predicate { climate in
                abs(climate.latitude - latitude) < 0.5 &&
                abs(climate.longitude - longitude) < 0.5
            }
        )

        do {
            climateData = try modelContext.fetch(descriptor)
        } catch {
            climateData = []
        }

        isLoading = false
    }
}

// MARK: - Climate Month Card

struct ClimateMonthCard: View {
    let climate: HistoricalClimate

    var body: some View {
        HStack(spacing: 12) {
            // Month indicator
            VStack {
                Text(shortMonthName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Image(systemName: climate.seasonCategory.icon)
                    .font(.title2)
                    .foregroundStyle(seasonColor)
            }
            .frame(width: 44)

            // Temperature
            VStack(alignment: .leading, spacing: 2) {
                Text("Temperature")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(climate.temperatureRangeText)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            // Precipitation
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: climate.precipitationCategory.icon)
                        .font(.caption)
                    Text(precipitationText)
                        .font(.caption)
                }
                .foregroundStyle(.blue)

                if let snow = climate.avgSnowfallCm, snow > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "snowflake")
                            .font(.caption)
                        Text("\(Int(snow)) cm")
                            .font(.caption)
                    }
                    .foregroundStyle(.cyan)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = climate.month
        components.day = 1
        components.year = 2024
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    private var seasonColor: Color {
        switch climate.seasonCategory.color {
        case "purple": return .purple
        case "blue": return .blue
        case "teal": return .teal
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }

    private var precipitationText: String {
        if let mm = climate.avgPrecipitationMm {
            return "\(Int(mm)) mm"
        }
        return "N/A"
    }
}

// MARK: - Climate Detail Section

struct ClimateDetailSection: View {
    let climate: HistoricalClimate

    var body: some View {
        VStack(spacing: 12) {
            // Temperature details
            GroupBox {
                VStack(spacing: 8) {
                    detailRow(
                        icon: "thermometer.high",
                        label: "Avg High",
                        value: formatTemp(climate.avgHighCelsius)
                    )
                    detailRow(
                        icon: "thermometer.low",
                        label: "Avg Low",
                        value: formatTemp(climate.avgLowCelsius)
                    )
                    if let recordHigh = climate.recordHighCelsius {
                        detailRow(
                            icon: "thermometer.sun.fill",
                            label: "Record High",
                            value: formatTemp(recordHigh)
                        )
                    }
                    if let recordLow = climate.recordLowCelsius {
                        detailRow(
                            icon: "thermometer.snowflake",
                            label: "Record Low",
                            value: formatTemp(recordLow)
                        )
                    }
                }
            } label: {
                Label("Temperature", systemImage: "thermometer.medium")
            }

            // Precipitation details
            GroupBox {
                VStack(spacing: 8) {
                    if let precip = climate.avgPrecipitationMm {
                        detailRow(
                            icon: "drop.fill",
                            label: "Avg Precipitation",
                            value: "\(Int(precip)) mm"
                        )
                    }
                    if let snow = climate.avgSnowfallCm {
                        detailRow(
                            icon: "snowflake",
                            label: "Avg Snowfall",
                            value: "\(Int(snow)) cm"
                        )
                    }
                    if let rainyDays = climate.avgRainyDays {
                        detailRow(
                            icon: "cloud.rain",
                            label: "Rainy Days",
                            value: "\(Int(rainyDays)) days"
                        )
                    }
                    if let snowyDays = climate.avgSnowyDays {
                        detailRow(
                            icon: "cloud.snow",
                            label: "Snowy Days",
                            value: "\(Int(snowyDays)) days"
                        )
                    }
                }
            } label: {
                Label("Precipitation", systemImage: "cloud.rain")
            }

            // Wind and daylight
            GroupBox {
                VStack(spacing: 8) {
                    if let wind = climate.avgWindSpeedKmh {
                        detailRow(
                            icon: "wind",
                            label: "Avg Wind",
                            value: "\(Int(wind)) km/h"
                        )
                    }
                    if let direction = climate.prevailingWindDirection {
                        detailRow(
                            icon: "location.north",
                            label: "Prevailing Wind",
                            value: direction
                        )
                    }
                    if let daylight = climate.avgDaylightHours {
                        detailRow(
                            icon: "sun.horizon",
                            label: "Daylight Hours",
                            value: String(format: "%.1f hrs", daylight)
                        )
                    }
                    if let humidity = climate.avgHumidity {
                        detailRow(
                            icon: "humidity",
                            label: "Avg Humidity",
                            value: "\(Int(humidity))%"
                        )
                    }
                }
            } label: {
                Label("Conditions", systemImage: "cloud.sun")
            }

            // Notes
            if !climate.seasonNotes.isEmpty {
                GroupBox {
                    Text(climate.seasonNotes)
                        .font(.caption)
                } label: {
                    Label("Season Notes", systemImage: "note.text")
                }
            }

            if !climate.hazardNotes.isEmpty {
                GroupBox {
                    Text(climate.hazardNotes)
                        .font(.caption)
                        .foregroundStyle(.orange)
                } label: {
                    Label("Hazard Notes", systemImage: "exclamationmark.triangle")
                }
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func formatTemp(_ celsius: Double?) -> String {
        guard let temp = celsius else { return "N/A" }
        let measurement = Measurement(value: temp, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: measurement)
    }
}

#Preview {
    NavigationStack {
        HistoricalClimateView(
            locationName: "Brooks Range, Alaska",
            latitude: 68.0,
            longitude: -150.0
        )
    }
    .modelContainer(for: HistoricalClimate.self, inMemory: true)
}
