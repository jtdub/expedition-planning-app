import SwiftUI

struct RouteMapOverlayView: View {
    @Bindable var viewModel: RouteMapViewModel
    let elevationUnit: ElevationUnit

    @State private var showingFilters = false
    @State private var showingElevation = false

    var body: some View {
        VStack(spacing: 0) {
            // Elevation chart overlay
            if showingElevation {
                elevationOverlay
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Stats bar and controls
            controlBar
        }
        .animation(.easeInOut(duration: 0.2), value: showingElevation)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            // Stats
            statsContent

            Spacer()

            // Control buttons
            controlButtons
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var statsContent: some View {
        HStack(spacing: 16) {
            // Distance
            VStack(alignment: .leading, spacing: 2) {
                Text("Distance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedTotalDistance)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Waypoints
            VStack(alignment: .leading, spacing: 2) {
                Text("Waypoints")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.statistics.waypointCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Elevation range
            if let high = viewModel.statistics.highestElevationMeters {
                VStack(alignment: .leading, spacing: 2) {
                    Text("High Point")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formattedElevation(high, unit: elevationUnit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 8) {
            // Filter button
            Button {
                showingFilters.toggle()
            } label: {
                Image(systemName: viewModel.selectedWaypointTypes.count < WaypointType.allCases.count
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
                )
                .font(.title2)
            }
            .popover(isPresented: $showingFilters) {
                filterContent
                    .presentationCompactAdaptation(.popover)
            }

            // Elevation toggle
            Button {
                showingElevation.toggle()
            } label: {
                let icon = showingElevation
                ? "chart.line.uptrend.xyaxis.circle.fill"
                : "chart.line.uptrend.xyaxis.circle"
            Image(systemName: icon)
                    .font(.title2)
            }
        }
    }

    // MARK: - Elevation Overlay

    private var elevationOverlay: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(.secondary.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Chart
            ElevationChartCompactView(
                data: viewModel.elevationChartData,
                unit: elevationUnit
            )
            .frame(height: 120)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }

    // MARK: - Filter Content

    private var filterContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter Waypoints")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    viewModel.showAllWaypointTypes()
                }
                .font(.caption)
            }

            Divider()

            // Shelter cabin toggle
            Toggle(isOn: $viewModel.showNearbyShelters) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.teal)
                    Text("Show Nearby Shelters")
                }
            }
            .toggleStyle(.switch)

            Divider()

            ForEach(WaypointType.allCases, id: \.self) { type in
                filterRow(for: type)
            }
        }
        .padding()
        .frame(width: 250)
    }

    private func filterRow(for type: WaypointType) -> some View {
        Button {
            viewModel.toggleWaypointTypeFilter(type)
        } label: {
            HStack {
                Circle()
                    .fill(type.color)
                    .frame(width: 12, height: 12)

                Text(type.rawValue)
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.selectedWaypointTypes.contains(type) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
