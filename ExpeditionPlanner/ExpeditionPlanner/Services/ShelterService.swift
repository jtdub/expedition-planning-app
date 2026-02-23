import Foundation
import CoreLocation

/// Service for managing shelter cabin data
struct ShelterService {
    // MARK: - Shelter Cabin Model

    struct ShelterCabin: Identifiable, Hashable {
        let id: UUID
        let name: String
        let coordinate: CLLocationCoordinate2D
        let elevationMeters: Double?
        let capacity: Int?
        let amenities: [Amenity]
        let notes: String?
        let region: Region

        init(
            id: UUID = UUID(),
            name: String,
            coordinate: CLLocationCoordinate2D,
            elevationMeters: Double? = nil,
            capacity: Int? = nil,
            amenities: [Amenity] = [],
            notes: String? = nil,
            region: Region = .alaska
        ) {
            self.id = id
            self.name = name
            self.coordinate = coordinate
            self.elevationMeters = elevationMeters
            self.capacity = capacity
            self.amenities = amenities
            self.notes = notes
            self.region = region
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum Amenity: String, CaseIterable {
        case woodStove = "Wood Stove"
        case sleepingPlatform = "Sleeping Platform"
        case firewood = "Firewood"
        case outhouse = "Outhouse"
        case water = "Water Source"
        case firstAid = "First Aid Kit"
        case emergencySupplies = "Emergency Supplies"
        case helipad = "Helipad"

        var icon: String {
            switch self {
            case .woodStove: return "flame.fill"
            case .sleepingPlatform: return "bed.double.fill"
            case .firewood: return "tree.fill"
            case .outhouse: return "toilet.fill"
            case .water: return "drop.fill"
            case .firstAid: return "cross.case.fill"
            case .emergencySupplies: return "bag.fill"
            case .helipad: return "airplane"
            }
        }
    }

    enum Region: String, CaseIterable {
        case alaska = "Alaska"
        case yukon = "Yukon"
        case brooksRange = "Brooks Range"
        case denali = "Denali Area"

        var description: String {
            switch self {
            case .alaska: return "General Alaska"
            case .yukon: return "Yukon Territory"
            case .brooksRange: return "Brooks Range, Alaska"
            case .denali: return "Denali National Park Area"
            }
        }
    }

    // MARK: - Sample Alaska/Yukon Shelter Data

    /// Sample shelter cabins for Alaska and Yukon expeditions
    /// Based on typical backcountry shelter locations in these regions
    static let sampleShelters: [ShelterCabin] = [
        // Brooks Range Shelters
        ShelterCabin(
            name: "Chandalar Shelf Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 67.8912, longitude: -148.4521),
            elevationMeters: 1220,
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood],
            notes: "Emergency shelter on Chandalar River route. Maintained by BLM.",
            region: .brooksRange
        ),
        ShelterCabin(
            name: "Atigun Pass Shelter",
            coordinate: CLLocationCoordinate2D(latitude: 68.1342, longitude: -149.4823),
            elevationMeters: 1463,
            capacity: 4,
            amenities: [.woodStove, .emergencySupplies, .firstAid],
            notes: "High pass emergency shelter. Often used as storm refuge.",
            region: .brooksRange
        ),
        ShelterCabin(
            name: "Galbraith Lake Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 68.4521, longitude: -149.5012),
            elevationMeters: 823,
            capacity: 8,
            amenities: [.woodStove, .sleepingPlatform, .firewood, .outhouse, .water],
            notes: "Popular staging point for Brooks Range expeditions.",
            region: .brooksRange
        ),
        ShelterCabin(
            name: "Anaktuvuk Pass Community Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 68.1433, longitude: -151.7350),
            elevationMeters: 661,
            capacity: 10,
            amenities: [.woodStove, .sleepingPlatform, .water, .firstAid],
            notes: "Located near village. Check with community before use.",
            region: .brooksRange
        ),

        // Denali Area Shelters
        ShelterCabin(
            name: "Wonder Lake Ranger Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 63.4534, longitude: -150.8723),
            elevationMeters: 610,
            capacity: 4,
            amenities: [.woodStove, .firstAid, .emergencySupplies],
            notes: "Emergency use only. Contact Denali NPS.",
            region: .denali
        ),
        ShelterCabin(
            name: "Kantishna Roadhouse Shelter",
            coordinate: CLLocationCoordinate2D(latitude: 63.5412, longitude: -150.9934),
            elevationMeters: 530,
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .water, .outhouse],
            notes: "Historic mining district shelter.",
            region: .denali
        ),

        // General Alaska
        ShelterCabin(
            name: "Wiseman Creek Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 67.4123, longitude: -150.1023),
            elevationMeters: 390,
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood, .outhouse],
            notes: "BLM public use cabin. Reservations required.",
            region: .alaska
        ),
        ShelterCabin(
            name: "Coldfoot Emergency Shelter",
            coordinate: CLLocationCoordinate2D(latitude: 67.2521, longitude: -150.1834),
            elevationMeters: 317,
            capacity: 8,
            amenities: [.woodStove, .sleepingPlatform, .firstAid, .emergencySupplies],
            notes: "Near Coldfoot services. Good staging point.",
            region: .alaska
        ),

        // Yukon
        ShelterCabin(
            name: "Tombstone Mountain Shelter",
            coordinate: CLLocationCoordinate2D(latitude: 64.4512, longitude: -138.2341),
            elevationMeters: 1100,
            capacity: 6,
            amenities: [.woodStove, .sleepingPlatform, .firewood],
            notes: "Tombstone Territorial Park emergency shelter.",
            region: .yukon
        ),
        ShelterCabin(
            name: "Grizzly Lake Cabin",
            coordinate: CLLocationCoordinate2D(latitude: 64.5234, longitude: -138.4521),
            elevationMeters: 980,
            capacity: 4,
            amenities: [.woodStove, .sleepingPlatform, .water],
            notes: "Remote backcountry cabin. Good bear country awareness needed.",
            region: .yukon
        ),
        ShelterCabin(
            name: "Divide Lake Shelter",
            coordinate: CLLocationCoordinate2D(latitude: 64.3892, longitude: -138.3012),
            elevationMeters: 1250,
            capacity: 4,
            amenities: [.woodStove, .emergencySupplies],
            notes: "High elevation emergency shelter.",
            region: .yukon
        )
    ]

    // MARK: - Filtering

    /// Get shelters by region
    static func shelters(in region: Region) -> [ShelterCabin] {
        sampleShelters.filter { $0.region == region }
    }

    /// Get shelters within a distance of a coordinate
    static func shelters(
        near coordinate: CLLocationCoordinate2D,
        withinMeters distance: Double
    ) -> [ShelterCabin] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return sampleShelters.filter { shelter in
            let shelterLocation = CLLocation(
                latitude: shelter.coordinate.latitude,
                longitude: shelter.coordinate.longitude
            )
            return location.distance(from: shelterLocation) <= distance
        }
    }

    /// Get shelters along a route (within distance of any route point)
    static func shelters(
        alongRoute coordinates: [CLLocationCoordinate2D],
        withinMeters distance: Double = 10000 // 10km default
    ) -> [ShelterCabin] {
        var nearShelters: Set<ShelterCabin> = []

        for coord in coordinates {
            let nearby = shelters(near: coord, withinMeters: distance)
            nearShelters.formUnion(nearby)
        }

        return Array(nearShelters).sorted { $0.name < $1.name }
    }

    // MARK: - Conversion to RouteWaypoint

    /// Convert a shelter to a RouteWaypoint for map display
    static func toWaypoint(_ shelter: ShelterCabin) -> RouteWaypoint {
        let amenityNotes = shelter.amenities.map { $0.rawValue }.joined(separator: ", ")
        let notes = [shelter.notes, "Amenities: \(amenityNotes)"]
            .compactMap { $0 }
            .joined(separator: "\n")

        return RouteWaypoint(
            id: shelter.id,
            coordinate: shelter.coordinate,
            name: shelter.name,
            type: .shelter,
            elevationMeters: shelter.elevationMeters,
            dayNumber: nil,
            date: nil,
            notes: notes.isEmpty ? nil : notes,
            sourceId: shelter.id
        )
    }

    /// Convert all shelters to RouteWaypoints
    static func allShelterWaypoints() -> [RouteWaypoint] {
        sampleShelters.map { toWaypoint($0) }
    }

    /// Get shelter waypoints for a specific region
    static func shelterWaypoints(in region: Region) -> [RouteWaypoint] {
        shelters(in: region).map { toWaypoint($0) }
    }

    /// Get shelter waypoints along a route
    static func shelterWaypoints(
        alongRoute coordinates: [CLLocationCoordinate2D],
        withinMeters distance: Double = 10000
    ) -> [RouteWaypoint] {
        shelters(alongRoute: coordinates, withinMeters: distance).map { toWaypoint($0) }
    }
}
