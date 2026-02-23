import SwiftUI
import SwiftData

/// Self-contained weather card that handles loading for a day
struct DayWeatherGroupBox: View {
    @Environment(\.modelContext)
    private var modelContext

    let day: ItineraryDay

    @State private var weatherForecast: WeatherForecast?
    @State private var isLoading = false

    var body: some View {
        GroupBox("Weather Forecast") {
            if isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading weather...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if let forecast = weatherForecast {
                WeatherSectionView(forecast: forecast) {
                    Task { await loadWeather() }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cloud.sun")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Weather data not loaded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await loadWeather() }
                    } label: {
                        Label("Load Weather", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .task { await loadWeather() }
    }

    private func loadWeather() async {
        guard let lat = day.endLatitude ?? day.startLatitude,
              let lon = day.endLongitude ?? day.startLongitude,
              let date = day.date else { return }

        isLoading = true
        let weatherService = WeatherService(modelContext: modelContext)
        let locationName = day.endLocation.isEmpty ? day.startLocation : day.endLocation

        do {
            weatherForecast = try await weatherService.fetchForecast(
                latitude: lat,
                longitude: lon,
                locationName: locationName,
                forDate: date,
                itineraryDayId: day.id
            )
        } catch {
            // Weather fetch failed - leave forecast nil
        }
        isLoading = false
    }
}

#Preview {
    DayWeatherGroupBox(day: {
        let day = ItineraryDay(
            dayNumber: 1,
            date: Date(),
            startLocation: "Base Camp",
            endLocation: "Camp 1",
            activityType: .fieldWork
        )
        day.startLatitude = -13.3695
        day.startLongitude = -72.5574
        return day
    }())
    .padding()
    .modelContainer(for: Expedition.self, inMemory: true)
}
