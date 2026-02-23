import SwiftUI

/// Compact weather display for an itinerary day
struct DayWeatherCard: View {
    let forecast: WeatherForecast?
    var isLoading: Bool = false
    var onRefresh: (() -> Void)?

    var body: some View {
        if isLoading {
            loadingView
        } else if let forecast = forecast {
            weatherContent(forecast)
        } else {
            noDataView
        }
    }

    @ViewBuilder
    private func weatherContent(_ forecast: WeatherForecast) -> some View {
        HStack(spacing: 12) {
            // Weather Icon
            Image(systemName: forecast.conditionIcon)
                .font(.title)
                .foregroundStyle(colorForCondition(forecast.conditionCode))
                .frame(width: 40)

            // Temperature
            VStack(alignment: .leading, spacing: 2) {
                if let high = forecast.temperatureHighCelsius {
                    Text(WeatherService.formatTemperature(high))
                        .font(.headline)
                }
                if let low = forecast.temperatureLowCelsius {
                    Text(WeatherService.formatTemperature(low))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Conditions
            VStack(alignment: .trailing, spacing: 2) {
                if let chance = forecast.precipitationChance, chance > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(forecast.precipitationChanceText)
                            .font(.caption)
                    }
                }

                if let wind = forecast.windSpeedKmh, wind > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "wind")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(WeatherService.formatWindSpeed(wind))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading weather...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var noDataView: some View {
        HStack {
            Image(systemName: "cloud.slash")
                .foregroundStyle(.secondary)
            Text("Weather unavailable")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        .padding(.vertical, 8)
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
        case "fog", "mist", "haze":
            return .secondary
        default:
            return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DayWeatherCard(
            forecast: {
                let forecast = WeatherForecast()
                forecast.conditionCode = "partlycloudy"
                forecast.temperatureHighCelsius = 18
                forecast.temperatureLowCelsius = 5
                forecast.precipitationChance = 0.3
                forecast.windSpeedKmh = 25
                return forecast
            }()
        )

        DayWeatherCard(forecast: nil)
        DayWeatherCard(forecast: nil, isLoading: true)
    }
    .padding()
}
