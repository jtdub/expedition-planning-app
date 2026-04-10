import Foundation
import MapKit
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "MapCacheService")

/// Represents a tile coordinate in the slippy map system
struct TileCoordinate {
    let tileX: Int
    let tileY: Int
    let zoom: Int
}

/// Service for managing offline map tile caching
final class MapCacheService: NSObject, ObservableObject {
    // MARK: - Properties

    static let shared = MapCacheService()

    @Published private(set) var isDownloading = false
    @Published private(set) var downloadProgress: Double = 0
    @Published private(set) var cachedRegions: [CachedRegion] = []
    @Published private(set) var totalCacheSize: Int64 = 0

    private let fileManager = FileManager.default
    private var downloadTask: URLSessionDataTask?
    private var tilesToDownload: [TileCoordinate] = []
    private var tilesDownloaded = 0
    private var currentRegionName = ""

    // MARK: - Cache Directory

    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("MapTiles", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        return cacheDir
    }

    private var regionsFile: URL {
        cacheDirectory.appendingPathComponent("regions.json")
    }

    // MARK: - Initialization

    override private init() {
        super.init()
        loadCachedRegions()
        calculateCacheSize()
    }

    // MARK: - Cached Region Model

    struct CachedRegion: Codable, Identifiable {
        let id: UUID
        let name: String
        let centerLatitude: Double
        let centerLongitude: Double
        let spanLatitude: Double
        let spanLongitude: Double
        let minZoom: Int
        let maxZoom: Int
        let tileCount: Int
        let downloadedAt: Date
        var sizeBytes: Int64

        var region: MKCoordinateRegion {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                span: MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude)
            )
        }

        var formattedSize: String {
            ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
        }
    }

    // MARK: - Download Region

    /// Download map tiles for a region
    func downloadRegion(
        name: String,
        region: MKCoordinateRegion,
        minZoom: Int = 10,
        maxZoom: Int = 15
    ) async throws {
        guard !isDownloading else {
            throw MapCacheError.alreadyDownloading
        }

        await MainActor.run {
            isDownloading = true
            downloadProgress = 0
            currentRegionName = name
        }

        defer {
            Task { @MainActor in
                isDownloading = false
            }
        }

        // Calculate tiles needed
        let tiles = calculateTiles(for: region, minZoom: minZoom, maxZoom: maxZoom)
        let totalTiles = tiles.count

        guard totalTiles > 0 else {
            throw MapCacheError.noTilesToDownload
        }

        logger.info("Starting download of \(totalTiles) tiles for region: \(name)")

        var downloadedCount = 0
        var totalSize: Int64 = 0

        // Download tiles
        for tile in tiles {
            do {
                let size = try await downloadTile(x: tile.tileX, y: tile.tileY, zoom: tile.zoom)
                totalSize += size
                downloadedCount += 1

                let progress = Double(downloadedCount) / Double(totalTiles)
                await MainActor.run {
                    downloadProgress = progress
                }
            } catch {
                let logMsg = "Failed to download tile (\(tile.tileX), \(tile.tileY), \(tile.zoom))"
                logger.warning("\(logMsg): \(error)")
                // Continue with other tiles
            }
        }

        // Save region metadata
        let cachedRegion = CachedRegion(
            id: UUID(),
            name: name,
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude,
            spanLatitude: region.span.latitudeDelta,
            spanLongitude: region.span.longitudeDelta,
            minZoom: minZoom,
            maxZoom: maxZoom,
            tileCount: downloadedCount,
            downloadedAt: Date(),
            sizeBytes: totalSize
        )

        await MainActor.run {
            cachedRegions.append(cachedRegion)
            saveCachedRegions()
            calculateCacheSize()
        }

        logger.info("Downloaded \(downloadedCount) tiles (\(cachedRegion.formattedSize)) for region: \(name)")
    }

    // MARK: - Tile Calculation

    private func calculateTiles(
        for region: MKCoordinateRegion,
        minZoom: Int,
        maxZoom: Int
    ) -> [TileCoordinate] {
        var tiles: [TileCoordinate] = []

        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2

        for zoom in minZoom...maxZoom {
            let minTileX = lonToTileX(minLon, zoom: zoom)
            let maxTileX = lonToTileX(maxLon, zoom: zoom)
            let minTileY = latToTileY(maxLat, zoom: zoom) // Note: Y is inverted
            let maxTileY = latToTileY(minLat, zoom: zoom)

            for xCoord in minTileX...maxTileX {
                for yCoord in minTileY...maxTileY {
                    tiles.append(TileCoordinate(tileX: xCoord, tileY: yCoord, zoom: zoom))
                }
            }
        }

        return tiles
    }

    private func lonToTileX(_ lon: Double, zoom: Int) -> Int {
        return Int(floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom))))
    }

    private func latToTileY(_ lat: Double, zoom: Int) -> Int {
        let latRad = lat * .pi / 180.0
        return Int(floor((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * pow(2.0, Double(zoom))))
    }

    // MARK: - Tile Download

    private func downloadTile(x: Int, y: Int, zoom: Int) async throws -> Int64 {
        // Check if already cached
        let tilePath = tilePath(x: x, y: y, zoom: zoom)
        if fileManager.fileExists(atPath: tilePath.path) {
            let attrs = try fileManager.attributesOfItem(atPath: tilePath.path)
            return attrs[.size] as? Int64 ?? 0
        }

        // Download from OpenStreetMap
        let urlString = "https://tile.openstreetmap.org/\(zoom)/\(x)/\(y).png"
        guard let url = URL(string: urlString) else {
            throw MapCacheError.invalidTileURL
        }

        var request = URLRequest(url: url)
        request.setValue("Chaki/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MapCacheError.downloadFailed
        }

        // Create directory structure
        let tileDir = tilePath.deletingLastPathComponent()
        try fileManager.createDirectory(at: tileDir, withIntermediateDirectories: true)

        // Save tile
        try data.write(to: tilePath)

        return Int64(data.count)
    }

    // MARK: - Tile Path

    func tilePath(x: Int, y: Int, zoom: Int) -> URL {
        cacheDirectory
            .appendingPathComponent("\(zoom)", isDirectory: true)
            .appendingPathComponent("\(x)", isDirectory: true)
            .appendingPathComponent("\(y).png")
    }

    /// Check if a tile is cached
    func hasCachedTile(x: Int, y: Int, zoom: Int) -> Bool {
        fileManager.fileExists(atPath: tilePath(x: x, y: y, zoom: zoom).path)
    }

    /// Get cached tile data
    func cachedTileData(x: Int, y: Int, zoom: Int) -> Data? {
        try? Data(contentsOf: tilePath(x: x, y: y, zoom: zoom))
    }

    // MARK: - Cache Management

    /// Delete a cached region
    func deleteRegion(_ region: CachedRegion) {
        cachedRegions.removeAll { $0.id == region.id }
        saveCachedRegions()
        calculateCacheSize()
    }

    /// Clear all cached tiles
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        cachedRegions.removeAll()
        saveCachedRegions()
        totalCacheSize = 0
        logger.info("Map cache cleared")
    }

    /// Calculate total cache size
    func calculateCacheSize() {
        var size: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attrs[.size] as? Int64 {
                    size += fileSize
                }
            }
        }

        totalCacheSize = size
    }

    var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: totalCacheSize, countStyle: .file)
    }

    // MARK: - Persistence

    private func loadCachedRegions() {
        guard fileManager.fileExists(atPath: regionsFile.path) else { return }

        do {
            let data = try Data(contentsOf: regionsFile)
            cachedRegions = try JSONDecoder().decode([CachedRegion].self, from: data)
        } catch {
            logger.error("Failed to load cached regions: \(error)")
        }
    }

    private func saveCachedRegions() {
        do {
            let data = try JSONEncoder().encode(cachedRegions)
            try data.write(to: regionsFile)
        } catch {
            logger.error("Failed to save cached regions: \(error)")
        }
    }

    // MARK: - Errors

    enum MapCacheError: LocalizedError {
        case alreadyDownloading
        case noTilesToDownload
        case invalidTileURL
        case downloadFailed

        var errorDescription: String? {
            switch self {
            case .alreadyDownloading:
                return "A download is already in progress"
            case .noTilesToDownload:
                return "No tiles to download for the specified region"
            case .invalidTileURL:
                return "Invalid tile URL"
            case .downloadFailed:
                return "Failed to download tile"
            }
        }
    }
}

// MARK: - Cached Tile Overlay

/// Custom tile overlay that serves cached tiles
class CachedTileOverlay: MKTileOverlay {
    private let cacheService = MapCacheService.shared

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // Return cached tile path if available
        let tilePath = cacheService.tilePath(x: path.x, y: path.y, zoom: path.z)
        if FileManager.default.fileExists(atPath: tilePath.path) {
            return tilePath
        }

        // Fall back to online tile
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png")!
    }

    override func loadTile(
        at path: MKTileOverlayPath,
        result: @escaping (Data?, Error?) -> Void
    ) {
        // Try cached tile first
        if let data = cacheService.cachedTileData(x: path.x, y: path.y, zoom: path.z) {
            result(data, nil)
            return
        }

        // Fall back to downloading
        super.loadTile(at: path, result: result)
    }
}
