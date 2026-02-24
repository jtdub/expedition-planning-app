import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "SatelliteDeviceViewModel")

enum SatelliteDeviceSortOrder: String, CaseIterable {
    case name = "Name"
    case type = "Device Type"
    case status = "Status"
    case assignee = "Assigned To"
}

@Observable
final class SatelliteDeviceViewModel {
    private var modelContext: ModelContext

    var devices: [SatelliteDevice] = []
    var searchText: String = ""
    var filterType: SatelliteDeviceType?
    var filterStatus: DeviceStatus?
    var showRentedOnly: Bool = false
    var sortOrder: SatelliteDeviceSortOrder = .name
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadDevices(for expedition: Expedition) {
        let allDevices = expedition.satelliteDevices ?? []

        var filtered = allDevices

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { device in
                device.name.localizedCaseInsensitiveContains(searchText) ||
                device.deviceId.localizedCaseInsensitiveContains(searchText) ||
                device.assignedToParticipant.localizedCaseInsensitiveContains(searchText) ||
                device.rentalCompany.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if let deviceType = filterType {
            filtered = filtered.filter { $0.deviceType == deviceType }
        }

        // Apply status filter
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply rented filter
        if showRentedOnly {
            filtered = filtered.filter { $0.isRented }
        }

        // Sort
        switch sortOrder {
        case .name:
            devices = filtered.sorted { $0.displayName < $1.displayName }
        case .type:
            devices = filtered.sorted {
                if $0.deviceType != $1.deviceType {
                    return $0.deviceType.rawValue < $1.deviceType.rawValue
                }
                return $0.displayName < $1.displayName
            }
        case .status:
            devices = filtered.sorted {
                if $0.status != $1.status {
                    return $0.status.rawValue < $1.status.rawValue
                }
                return $0.displayName < $1.displayName
            }
        case .assignee:
            devices = filtered.sorted {
                if $0.assignedToParticipant != $1.assignedToParticipant {
                    return $0.assignedToParticipant < $1.assignedToParticipant
                }
                return $0.displayName < $1.displayName
            }
        }
    }

    // MARK: - CRUD Operations

    func addDevice(_ device: SatelliteDevice, to expedition: Expedition) {
        device.expedition = expedition
        if expedition.satelliteDevices == nil {
            expedition.satelliteDevices = []
        }
        expedition.satelliteDevices?.append(device)
        modelContext.insert(device)

        logger.info("Added satellite device '\(device.displayName)' to expedition")
        saveContext()
        loadDevices(for: expedition)
    }

    func deleteDevice(_ device: SatelliteDevice, from expedition: Expedition) {
        let name = device.displayName
        expedition.satelliteDevices?.removeAll { $0.id == device.id }
        modelContext.delete(device)

        logger.info("Deleted satellite device '\(name)' from expedition")
        saveContext()
        loadDevices(for: expedition)
    }

    func updateDevice(_ device: SatelliteDevice, in expedition: Expedition) {
        logger.debug("Updated satellite device '\(device.displayName)'")
        saveContext()
        loadDevices(for: expedition)
    }

    // MARK: - Computed Properties

    var twoWayMessagingDevices: [SatelliteDevice] {
        devices.filter { $0.deviceType.hasTwoWayMessaging }
    }

    var trackingDevices: [SatelliteDevice] {
        devices.filter { $0.deviceType.hasTracking }
    }

    var rentedDevices: [SatelliteDevice] {
        devices.filter { $0.isRented }
    }

    var devicesNeedingPickup: [SatelliteDevice] {
        devices.filter { $0.needsPickup }
            .sorted { ($0.pickupDate ?? .distantFuture) < ($1.pickupDate ?? .distantFuture) }
    }

    var devicesNeedingReturn: [SatelliteDevice] {
        devices.filter { $0.needsReturn }
            .sorted { ($0.returnDate ?? .distantFuture) < ($1.returnDate ?? .distantFuture) }
    }

    var groupedByType: [(type: SatelliteDeviceType, devices: [SatelliteDevice])] {
        let grouped = Dictionary(grouping: devices) { $0.deviceType }
        return SatelliteDeviceType.allCases.compactMap { type in
            guard let list = grouped[type], !list.isEmpty else { return nil }
            return (type: type, devices: list)
        }
    }

    var groupedByAssignee: [(assignee: String, devices: [SatelliteDevice])] {
        let grouped = Dictionary(grouping: devices) {
            $0.assignedToParticipant.isEmpty ? "Unassigned" : $0.assignedToParticipant
        }
        return grouped.keys.sorted().compactMap { assignee in
            guard let list = grouped[assignee], !list.isEmpty else { return nil }
            return (assignee: assignee, devices: list)
        }
    }

    var totalRentalCost: Decimal {
        devices.compactMap { $0.rentalCost }.reduce(0, +)
    }

    var totalMonthlyFees: Decimal {
        devices.compactMap { $0.monthlyFee }.reduce(0, +)
    }

    var assignedCount: Int {
        devices.filter { !$0.assignedToParticipant.isEmpty }.count
    }

    var expiringSubscriptionsCount: Int {
        guard let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) else {
            return 0
        }
        return devices.filter { device in
            guard let expiry = device.subscriptionExpiry else { return false }
            return expiry < thirtyDaysFromNow
        }.count
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterType = nil
        filterStatus = nil
        showRentedOnly = false
    }

    var hasActiveFilters: Bool {
        filterType != nil || filterStatus != nil || showRentedOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save satellite device changes: \(error.localizedDescription)")
        }
    }
}
