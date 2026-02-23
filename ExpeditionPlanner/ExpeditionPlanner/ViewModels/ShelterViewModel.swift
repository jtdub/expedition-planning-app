import Foundation
import SwiftData
import CoreLocation

@Observable
final class ShelterViewModel {
    private var modelContext: ModelContext

    var shelters: [Shelter] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Loading

    func loadAllShelters() {
        let descriptor = FetchDescriptor<Shelter>(
            sortBy: [SortDescriptor(\.name)]
        )
        do {
            shelters = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load shelters: \(error.localizedDescription)"
        }
    }

    func loadShelters(inRegion region: String) {
        let descriptor = FetchDescriptor<Shelter>(
            predicate: #Predicate { shelter in
                shelter.region == region
            },
            sortBy: [SortDescriptor(\.name)]
        )
        do {
            shelters = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load shelters: \(error.localizedDescription)"
        }
    }

    func loadShelters(ofType type: ShelterType) {
        let typeValue = type.rawValue
        let descriptor = FetchDescriptor<Shelter>(
            predicate: #Predicate { shelter in
                shelter.shelterType.rawValue == typeValue
            },
            sortBy: [SortDescriptor(\.name)]
        )
        do {
            shelters = try modelContext.fetch(descriptor)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load shelters: \(error.localizedDescription)"
        }
    }

    // MARK: - CRUD Operations

    func addShelter(_ shelter: Shelter) {
        shelter.isUserAdded = true
        modelContext.insert(shelter)
        saveContext()
        loadAllShelters()
    }

    func updateShelter(_ shelter: Shelter) {
        saveContext()
        loadAllShelters()
    }

    func deleteShelter(_ shelter: Shelter) {
        modelContext.delete(shelter)
        saveContext()
        loadAllShelters()
    }

    // MARK: - Seeding

    func seedIfNeeded() {
        let descriptor = FetchDescriptor<Shelter>()
        do {
            let count = try modelContext.fetchCount(descriptor)
            if count == 0 {
                seedShelters()
            }
        } catch {
            seedShelters()
        }
    }

    private func seedShelters() {
        let shelterData = ShelterService.sampleShelterData
        for data in shelterData {
            let shelter = Shelter(
                name: data.name,
                shelterType: data.shelterType,
                latitude: data.latitude,
                longitude: data.longitude,
                elevationMeters: data.elevationMeters,
                region: data.region,
                capacity: data.capacity,
                notes: data.notes,
                isUserAdded: false
            )
            shelter.hasWoodStove = data.amenities.contains(.woodStove)
            shelter.hasSleepingPlatform = data.amenities.contains(.sleepingPlatform)
            shelter.hasFirewood = data.amenities.contains(.firewood)
            shelter.hasOuthouse = data.amenities.contains(.outhouse)
            shelter.hasWater = data.amenities.contains(.water)
            shelter.hasFirstAid = data.amenities.contains(.firstAid)
            shelter.hasEmergencySupplies = data.amenities.contains(.emergencySupplies)
            shelter.hasHelipad = data.amenities.contains(.helipad)
            modelContext.insert(shelter)
        }
        saveContext()
    }

    // MARK: - Location Queries

    func shelters(near coordinate: CLLocationCoordinate2D, withinMeters distance: Double) -> [Shelter] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return shelters.filter { shelter in
            guard let lat = shelter.latitude, let lon = shelter.longitude else { return false }
            let shelterLocation = CLLocation(latitude: lat, longitude: lon)
            return location.distance(from: shelterLocation) <= distance
        }
    }

    func shelters(
        alongRoute coordinates: [CLLocationCoordinate2D],
        withinMeters distance: Double = 10000
    ) -> [Shelter] {
        var nearShelters: Set<UUID> = []
        var result: [Shelter] = []

        for coord in coordinates {
            let nearby = shelters(near: coord, withinMeters: distance)
            for shelter in nearby where !nearShelters.contains(shelter.id) {
                nearShelters.insert(shelter.id)
                result.append(shelter)
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Statistics

    var sheltersByRegion: [String: Int] {
        var result: [String: Int] = [:]
        for shelter in shelters {
            result[shelter.region, default: 0] += 1
        }
        return result
    }

    var sheltersByType: [ShelterType: Int] {
        var result: [ShelterType: Int] = [:]
        for shelter in shelters {
            result[shelter.shelterType, default: 0] += 1
        }
        return result
    }

    var userAddedCount: Int {
        shelters.filter { $0.isUserAdded }.count
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
