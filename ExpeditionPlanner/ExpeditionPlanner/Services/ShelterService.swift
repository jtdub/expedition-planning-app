import Foundation
import CoreLocation

/// Service for managing shelter data and conversions
struct ShelterService {
    // MARK: - Seed Data Structure

    struct ShelterSeedData {
        let name: String
        let shelterType: ShelterType
        let latitude: Double
        let longitude: Double
        let elevationMeters: Double?
        let region: String
        let capacity: Int?
        let amenities: [ShelterAmenity]
        let notes: String
    }

    // MARK: - Sample Alaska/Yukon Shelter Seed Data

    /// Sample shelter data for seeding the database
    static let sampleShelterData: [ShelterSeedData] = [
        // Brooks Range Shelters
        ShelterSeedData(
            name: "Chandalar Shelf Cabin",
            shelterType: .publicCabin,
            latitude: 67.8912,
            longitude: -148.4521,
            elevationMeters: 1220,
            region: "Brooks Range",
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood],
            notes: "Emergency shelter on Chandalar River route. Maintained by BLM."
        ),
        ShelterSeedData(
            name: "Atigun Pass Shelter",
            shelterType: .emergencyShelter,
            latitude: 68.1342,
            longitude: -149.4823,
            elevationMeters: 1463,
            region: "Brooks Range",
            capacity: 4,
            amenities: [.woodStove, .emergencySupplies, .firstAid],
            notes: "High pass emergency shelter. Often used as storm refuge."
        ),
        ShelterSeedData(
            name: "Galbraith Lake Cabin",
            shelterType: .publicCabin,
            latitude: 68.4521,
            longitude: -149.5012,
            elevationMeters: 823,
            region: "Brooks Range",
            capacity: 8,
            amenities: [.woodStove, .sleepingPlatform, .firewood, .outhouse, .water],
            notes: "Popular staging point for Brooks Range expeditions."
        ),
        ShelterSeedData(
            name: "Anaktuvuk Pass Community Cabin",
            shelterType: .publicCabin,
            latitude: 68.1433,
            longitude: -151.7350,
            elevationMeters: 661,
            region: "Brooks Range",
            capacity: 10,
            amenities: [.woodStove, .sleepingPlatform, .water, .firstAid],
            notes: "Located near village. Check with community before use."
        ),

        // Denali Area Shelters
        ShelterSeedData(
            name: "Wonder Lake Ranger Cabin",
            shelterType: .emergencyShelter,
            latitude: 63.4534,
            longitude: -150.8723,
            elevationMeters: 610,
            region: "Denali Area",
            capacity: 4,
            amenities: [.woodStove, .firstAid, .emergencySupplies],
            notes: "Emergency use only. Contact Denali NPS."
        ),
        ShelterSeedData(
            name: "Kantishna Roadhouse Shelter",
            shelterType: .hut,
            latitude: 63.5412,
            longitude: -150.9934,
            elevationMeters: 530,
            region: "Denali Area",
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .water, .outhouse],
            notes: "Historic mining district shelter."
        ),

        // General Alaska
        ShelterSeedData(
            name: "Wiseman Creek Cabin",
            shelterType: .publicCabin,
            latitude: 67.4123,
            longitude: -150.1023,
            elevationMeters: 390,
            region: "Alaska",
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood, .outhouse],
            notes: "BLM public use cabin. Reservations required."
        ),
        ShelterSeedData(
            name: "Coldfoot Emergency Shelter",
            shelterType: .emergencyShelter,
            latitude: 67.2521,
            longitude: -150.1834,
            elevationMeters: 317,
            region: "Alaska",
            capacity: 8,
            amenities: [.woodStove, .sleepingPlatform, .firstAid, .emergencySupplies],
            notes: "Near Coldfoot services. Good staging point."
        ),

        // Yukon
        ShelterSeedData(
            name: "Tombstone Mountain Shelter",
            shelterType: .emergencyShelter,
            latitude: 64.4512,
            longitude: -138.2341,
            elevationMeters: 1100,
            region: "Yukon",
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood],
            notes: "Tombstone Territorial Park emergency shelter."
        ),
        ShelterSeedData(
            name: "Grizzly Lake Cabin",
            shelterType: .publicCabin,
            latitude: 64.5234,
            longitude: -138.4521,
            elevationMeters: 980,
            region: "Yukon",
            capacity: 4,
            amenities: [.woodStove, .sleepingPlatform, .water],
            notes: "Remote backcountry cabin. Good bear country awareness needed."
        ),
        ShelterSeedData(
            name: "Divide Lake Shelter",
            shelterType: .emergencyShelter,
            latitude: 64.3892,
            longitude: -138.3012,
            elevationMeters: 1250,
            region: "Yukon",
            capacity: 4,
            amenities: [.woodStove, .emergencySupplies],
            notes: "High elevation emergency shelter."
        )
    ]

    // MARK: - Conversion to RouteWaypoint

    /// Convert a Shelter model to a RouteWaypoint for map display
    static func toWaypoint(_ shelter: Shelter) -> RouteWaypoint? {
        guard let coordinate = shelter.coordinate else { return nil }

        let amenityNotes = shelter.amenitySummary
        let notes = [shelter.notes, amenityNotes.isEmpty ? nil : "Amenities: \(amenityNotes)"]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        return RouteWaypoint(
            id: shelter.id,
            coordinate: coordinate,
            name: shelter.name,
            type: .shelter,
            elevationMeters: shelter.elevationMeters,
            dayNumber: nil,
            date: nil,
            notes: notes.isEmpty ? nil : notes,
            sourceId: shelter.id
        )
    }

    /// Convert an array of shelters to RouteWaypoints
    static func toWaypoints(_ shelters: [Shelter]) -> [RouteWaypoint] {
        shelters.compactMap { toWaypoint($0) }
    }

    // MARK: - Location Queries (Static, for use without SwiftData)

    /// Get shelters from seed data within a distance of a coordinate
    static func seedShelters(
        near coordinate: CLLocationCoordinate2D,
        withinMeters distance: Double
    ) -> [ShelterSeedData] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return sampleShelterData.filter { shelter in
            let shelterLocation = CLLocation(
                latitude: shelter.latitude,
                longitude: shelter.longitude
            )
            return location.distance(from: shelterLocation) <= distance
        }
    }

    /// Get shelters from seed data along a route
    static func seedShelters(
        alongRoute coordinates: [CLLocationCoordinate2D],
        withinMeters distance: Double = 10000
    ) -> [ShelterSeedData] {
        var seenNames: Set<String> = []
        var nearShelters: [ShelterSeedData] = []

        for coord in coordinates {
            let nearby = seedShelters(near: coord, withinMeters: distance)
            for shelter in nearby where !seenNames.contains(shelter.name) {
                seenNames.insert(shelter.name)
                nearShelters.append(shelter)
            }
        }

        return nearShelters.sorted { $0.name < $1.name }
    }

    // MARK: - Region List

    static var availableRegions: [String] {
        Array(Set(sampleShelterData.map { $0.region })).sorted()
    }
}
