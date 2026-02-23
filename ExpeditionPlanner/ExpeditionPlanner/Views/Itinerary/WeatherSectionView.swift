import SwiftUI
import SwiftData

/// Expanded weather section for day detail view
struct WeatherSectionView: View {
    let forecast: WeatherForecast
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: forecast.conditionIcon)
                    .font(.title)
                    .foregroundStyle(colorForCondition(forecast.conditionCode))

                VStack(alignment: .leading) {
                    Text(forecast.conditionDescription.isEmpty ? forecast.conditionCode : forecast.conditionDescription)
                        .font(.headline)
                        .textCase(.none)
                    Text(forecast.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let refresh = onRefresh {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                }
            }

            // Temperature
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(WeatherService.formatTemperature(forecast.temperatureHighCelsius))
                        .font(.title2)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading) {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(WeatherService.formatTemperature(forecast.temperatureLowCelsius))
                        .font(.title2)
                        .fontWeight(.medium)
                }

                Spacer()
            }

            // Details Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let chance = forecast.precipitationChance {
                    WeatherDetailItem(
                        icon: "drop.fill",
                        label: "Precipitation",
                        value: WeatherService.formatPrecipitationChance(chance),
                        color: .blue
                    )
                }

                if let wind = forecast.windSpeedKmh {
                    WeatherDetailItem(
                        icon: "wind",
                        label: "Wind",
                        value: WeatherService.formatWindSpeed(wind),
                        color: .gray
                    )
                }

                if let uv = forecast.uvIndex {
                    WeatherDetailItem(
                        icon: "sun.max",
                        label: "UV Index",
                        value: "\(uv)",
                        color: uvColor(uv)
                    )
                }

                if let humidity = forecast.humidity {
                    WeatherDetailItem(
                        icon: "humidity.fill",
                        label: "Humidity",
                        value: "\(Int(humidity * 100))%",
                        color: .cyan
                    )
                }
            }

            // Sunrise/Sunset
            if let sunrise = forecast.sunriseTime, let sunset = forecast.sunsetTime {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .foregroundStyle(.orange)
                        Text(formatTime(sunrise))
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "sunset.fill")
                            .foregroundStyle(.orange)
                        Text(formatTime(sunset))
                            .font(.caption)
                    }

                    if let hours = forecast.daylightHours {
                        Spacer()
                        Text(String(format: "%.1f hrs daylight", hours))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            // Data Source
            HStack {
                Text("Source: \(forecast.dataSource)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Updated: \(formatTime(forecast.fetchedAt))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func colorForCondition(_ code: String) -> Color {
        switch code.lowercased() {
        case "clear", "sunny", "mostlyclear":
            return .yellow
        case "partlycloudy":
            return .orange
        case "cloudy", "overcast", "mostlycloudy":
            return .gray
        case "rain", "drizzle", "showers", "heavyrain":
            return .blue
        case "thunderstorm", "thunderstorms":
            return .purple
        case "snow", "flurries", "heavysnow", "blizzard":
            return .cyan
        default:
            return .secondary
        }
    }

    private func uvColor(_ index: Int) -> Color {
        switch index {
        case 0...2: return .green
        case 3...5: return .yellow
        case 6...7: return .orange
        case 8...10: return .red
        default: return .purple
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Weather Detail Item

struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    WeatherSectionView(
        forecast: {
            let forecast = WeatherForecast()
            forecast.locationName = "Galbraith Lake"
            forecast.conditionCode = "partlycloudy"
            forecast.conditionDescription = "Partly Cloudy"
            forecast.temperatureHighCelsius = 18
            forecast.temperatureLowCelsius = 5
            forecast.precipitationChance = 0.3
            forecast.windSpeedKmh = 25
            forecast.uvIndex = 6
            forecast.humidity = 0.65
            forecast.sunriseTime = Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: Date())
            forecast.sunsetTime = Calendar.current.date(bySettingHour: 22, minute: 45, second: 0, of: Date())
            forecast.fetchedAt = Date()
            forecast.dataSource = "WeatherKit"
            return forecast
        }()
    )
    .padding()
}
