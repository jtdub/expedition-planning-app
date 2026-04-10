import Foundation
import CoreLocation

/// Service for managing shelter data and conversions
struct ShelterService {
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

}
