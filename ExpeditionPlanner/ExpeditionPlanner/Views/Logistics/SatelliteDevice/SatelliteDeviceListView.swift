import SwiftUI
import SwiftData

struct SatelliteDeviceListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: SatelliteDeviceViewModel?
    @State private var showingAddSheet = false
    @State private var selectedDevice: SatelliteDevice?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                deviceList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Satellite Devices")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.devices.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    viewModel?.loadDevices(for: expedition)
                }
            ),
            prompt: "Search devices"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    SatelliteDeviceFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedDevice) { device in
            if let viewModel = viewModel {
                NavigationStack {
                    SatelliteDeviceDetailView(
                        device: device,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SatelliteDeviceViewModel(modelContext: modelContext)
            }
            viewModel?.loadDevices(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func deviceList(viewModel: SatelliteDeviceViewModel) -> some View {
        if viewModel.devices.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Satellite Devices", systemImage: "antenna.radiowaves.left.and.right")
            } description: {
                Text("Add satellite communicators, PLBs, and radios for your expedition.")
            } actions: {
                Button("Add Device") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.devices.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryView(viewModel: viewModel)
                }

                // Alerts
                if !viewModel.devicesNeedingPickup.isEmpty || !viewModel.devicesNeedingReturn.isEmpty {
                    Section {
                        ForEach(viewModel.devicesNeedingPickup) { device in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Pick up: \(device.displayName)")
                                    .font(.subheadline)
                            }
                        }
                        ForEach(viewModel.devicesNeedingReturn) { device in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.blue)
                                Text("Return: \(device.displayName)")
                                    .font(.subheadline)
                            }
                        }
                    } header: {
                        Label("Action Required", systemImage: "exclamationmark.triangle")
                    }
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped by type
                ForEach(viewModel.groupedByType, id: \.type) { group in
                    Section {
                        ForEach(group.devices) { device in
                            SatelliteDeviceRowView(device: device)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDevice = device
                                }
                        }
                        .onDelete { indexSet in
                            deleteDevices(at: indexSet, from: group.devices, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.type.icon)
                            Text(group.type.rawValue)
                            Text("(\(group.devices.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: SatelliteDeviceViewModel) -> some View {
        HStack(spacing: 16) {
            SatDeviceStatBadge(
                value: "\(viewModel.devices.count)",
                label: "Total",
                icon: "antenna.radiowaves.left.and.right",
                color: .blue
            )
            SatDeviceStatBadge(
                value: "\(viewModel.twoWayMessagingDevices.count)",
                label: "2-Way",
                icon: "message",
                color: .green
            )
            SatDeviceStatBadge(
                value: "\(viewModel.assignedCount)",
                label: "Assigned",
                icon: "person.badge.clock",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: SatelliteDeviceViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text("Filtered")
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadDevices(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: SatelliteDeviceViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadDevices(for: expedition)
            } label: {
                Label("Clear Filters", systemImage: viewModel.hasActiveFilters ? "" : "checkmark")
            }

            Divider()

            Menu("Device Type") {
                Button {
                    viewModel.filterType = nil
                    viewModel.loadDevices(for: expedition)
                } label: {
                    Label("All Types", systemImage: viewModel.filterType == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(SatelliteDeviceType.allCases, id: \.self) { type in
                    Button {
                        viewModel.filterType = type
                        viewModel.loadDevices(for: expedition)
                    } label: {
                        Label(type.rawValue, systemImage: viewModel.filterType == type ? "checkmark" : type.icon)
                    }
                }
            }

            Menu("Status") {
                Button {
                    viewModel.filterStatus = nil
                    viewModel.loadDevices(for: expedition)
                } label: {
                    Label("All Statuses", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(DeviceStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.filterStatus = status
                        viewModel.loadDevices(for: expedition)
                    } label: {
                        Label(status.rawValue, systemImage: viewModel.filterStatus == status ? "checkmark" : "")
                    }
                }
            }

            Divider()

            Toggle("Rented Only", isOn: Binding(
                get: { viewModel.showRentedOnly },
                set: { newValue in
                    viewModel.showRentedOnly = newValue
                    viewModel.loadDevices(for: expedition)
                }
            ))

            Divider()

            Menu("Sort By") {
                ForEach(SatelliteDeviceSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadDevices(for: expedition)
                    } label: {
                        Label(order.rawValue, systemImage: viewModel.sortOrder == order ? "checkmark" : "")
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Delete

    private func deleteDevices(
        at indexSet: IndexSet,
        from devices: [SatelliteDevice],
        viewModel: SatelliteDeviceViewModel
    ) {
        for index in indexSet {
            viewModel.deleteDevice(devices[index], from: expedition)
        }
    }
}

// MARK: - Sat Device Stat Badge

struct SatDeviceStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Satellite Device Row View

struct SatelliteDeviceRowView: View {
    let device: SatelliteDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.deviceType.icon)
                .font(.title2)
                .foregroundStyle(typeColor)
                .frame(width: 40, height: 40)
                .background(typeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(device.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if device.deviceType.hasTwoWayMessaging {
                        Label("2-Way", systemImage: "message")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if device.deviceType.hasTracking {
                        Label("Tracking", systemImage: "location")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                if !device.assignedToParticipant.isEmpty {
                    Text("Assigned: \(device.assignedToParticipant)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(device.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                if device.isRented {
                    Text("Rented")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeColor: Color {
        switch device.deviceType.color {
        case "orange": return .orange
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "red": return .red
        case "green": return .green
        default: return .secondary
        }
    }

    private var statusColor: Color {
        switch device.status.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        case "purple": return .purple
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        SatelliteDeviceListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, SatelliteDevice.self], inMemory: true)
}
