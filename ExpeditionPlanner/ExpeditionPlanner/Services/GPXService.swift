import Foundation
import CoreLocation

// MARK: - GPX Service

struct GPXService {
    // MARK: - GPX Parsing

    struct GPXParseResult {
        let waypoints: [RouteWaypoint]
        let trackPoints: [CLLocationCoordinate2D]
        let name: String?
        let description: String?
    }

    /// Parse GPX data into waypoints and track points
    static func parse(data: Data) -> GPXParseResult? {
        let parser = GPXParser(data: data)
        return parser.parse()
    }

    /// Parse GPX from a URL
    static func parse(url: URL) -> GPXParseResult? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return parse(data: data)
    }

    // MARK: - GPX Export

    /// Export waypoints and track to GPX 1.1 format
    static func export(
        waypoints: [RouteWaypoint],
        trackCoordinates: [CLLocationCoordinate2D],
        name: String? = nil,
        description: String? = nil
    ) -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Chaki"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
        """

        // Metadata
        if let name {
            gpx += "\n  <metadata>\n    <name>\(escapeXML(name))</name>"
            if let description {
                gpx += "\n    <desc>\(escapeXML(description))</desc>"
            }
            gpx += "\n    <time>\(ISO8601DateFormatter().string(from: Date()))</time>"
            gpx += "\n  </metadata>"
        }

        // Waypoints
        for waypoint in waypoints {
            gpx += "\n  <wpt lat=\"\(waypoint.coordinate.latitude)\" lon=\"\(waypoint.coordinate.longitude)\">"
            if let elevation = waypoint.elevationMeters {
                gpx += "\n    <ele>\(elevation)</ele>"
            }
            gpx += "\n    <name>\(escapeXML(waypoint.name))</name>"
            gpx += "\n    <type>\(escapeXML(waypoint.type.rawValue))</type>"
            if let notes = waypoint.notes {
                gpx += "\n    <desc>\(escapeXML(notes))</desc>"
            }
            gpx += "\n  </wpt>"
        }

        // Track
        if !trackCoordinates.isEmpty {
            gpx += "\n  <trk>"
            if let name {
                gpx += "\n    <name>\(escapeXML(name)) Track</name>"
            }
            gpx += "\n    <trkseg>"

            for coord in trackCoordinates {
                gpx += "\n      <trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\"/>"
            }

            gpx += "\n    </trkseg>"
            gpx += "\n  </trk>"
        }

        gpx += "\n</gpx>\n"

        return gpx
    }

    /// Export to a file URL
    static func export(
        waypoints: [RouteWaypoint],
        trackCoordinates: [CLLocationCoordinate2D],
        name: String,
        to url: URL
    ) throws {
        let gpxString = export(
            waypoints: waypoints,
            trackCoordinates: trackCoordinates,
            name: name
        )
        try gpxString.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Helpers

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - GPX Parser

private class GPXParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var waypoints: [RouteWaypoint] = []
    private var trackPoints: [CLLocationCoordinate2D] = []
    private var gpxName: String?
    private var gpxDescription: String?

    // Current parsing state
    private var currentElement: String = ""
    private var currentText: String = ""

    // Current waypoint data
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentElevation: Double?
    private var currentName: String?
    private var currentType: String?
    private var currentDesc: String?

    // Track state
    private var inTrack = false
    private var inTrackSegment = false

    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> GPXService.GPXParseResult? {
        guard parser.parse() else {
            return nil
        }

        return GPXService.GPXParseResult(
            waypoints: waypoints,
            trackPoints: trackPoints,
            name: gpxName,
            description: gpxDescription
        )
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "wpt", "trkpt":
            currentLat = Double(attributeDict["lat"] ?? "")
            currentLon = Double(attributeDict["lon"] ?? "")
            currentElevation = nil
            currentName = nil
            currentType = nil
            currentDesc = nil

        case "trk":
            inTrack = true

        case "trkseg":
            inTrackSegment = true

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "name":
            if inTrack {
                // Track name, ignore for now
            } else if currentLat != nil {
                currentName = trimmedText
            } else {
                gpxName = trimmedText
            }

        case "desc":
            if currentLat != nil {
                currentDesc = trimmedText
            } else {
                gpxDescription = trimmedText
            }

        case "ele":
            currentElevation = Double(trimmedText)

        case "type":
            currentType = trimmedText

        case "wpt":
            if let lat = currentLat, let lon = currentLon {
                let waypointType = parseWaypointType(currentType)
                let waypoint = RouteWaypoint(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    name: currentName ?? "Waypoint",
                    type: waypointType,
                    elevationMeters: currentElevation,
                    notes: currentDesc,
                    sourceId: UUID()
                )
                waypoints.append(waypoint)
            }
            resetCurrentWaypoint()

        case "trkpt":
            if let lat = currentLat, let lon = currentLon {
                trackPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            resetCurrentWaypoint()

        case "trkseg":
            inTrackSegment = false

        case "trk":
            inTrack = false

        default:
            break
        }

        currentElement = ""
    }

    private func resetCurrentWaypoint() {
        currentLat = nil
        currentLon = nil
        currentElevation = nil
        currentName = nil
        currentType = nil
        currentDesc = nil
    }

    private func parseWaypointType(_ typeString: String?) -> WaypointType {
        guard let typeString = typeString?.lowercased() else {
            return .waypoint
        }

        // Try to match known types
        switch typeString {
        case "start", "start point", "trailhead":
            return .startPoint
        case "end", "end point", "finish":
            return .endPoint
        case "camp", "campsite", "camping":
            return .campsite
        case "resupply", "supply":
            return .resupply
        case "summit", "peak":
            return .summit
        case "hazard", "danger", "warning":
            return .hazard
        case "shelter", "cabin", "hut", "refuge":
            return .shelter
        default:
            // Check if any WaypointType rawValue matches
            if let matchedType = WaypointType.allCases.first(where: { $0.rawValue.lowercased() == typeString }) {
                return matchedType
            }
            return .waypoint
        }
    }
}
