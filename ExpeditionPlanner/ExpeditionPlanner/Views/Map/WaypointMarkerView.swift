import SwiftUI
import MapKit

struct WaypointMarkerView: View {
    let waypoint: RouteWaypoint

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(waypoint.type.color)
                .frame(width: 32, height: 32)

            // Icon
            Image(systemName: waypoint.type.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

struct WaypointAnnotation: View {
    let waypoint: RouteWaypoint
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Marker
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(waypoint.type.color, lineWidth: 3)
                        .frame(width: 44, height: 44)
                }

                // Marker content
                Circle()
                    .fill(waypoint.type.color)
                    .frame(width: 36, height: 36)

                Image(systemName: waypoint.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Pointer triangle
            Triangle()
                .fill(waypoint.type.color)
                .frame(width: 12, height: 8)
                .offset(y: -2)

            // Label
            if isSelected {
                Text(waypoint.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 4)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Waypoint Type Badge

struct WaypointTypeBadge: View {
    let type: WaypointType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ? type.color.opacity(0.2) : Color(.systemGray5),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? type.color : .secondary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? type.color : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Waypoint Type Legend

struct WaypointTypeLegend: View {
    let waypointCounts: [WaypointType: Int]

    private var sortedTypes: [WaypointType] {
        waypointCounts.keys.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedTypes, id: \.self) { type in
                if let count = waypointCounts[type], count > 0 {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(type.color)
                            .frame(width: 12, height: 12)

                        Text(type.rawValue)
                            .font(.caption)

                        Spacer()

                        Text("\(count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Marker") {
    WaypointMarkerView(
        waypoint: RouteWaypoint(
            coordinate: .init(latitude: 0, longitude: 0),
            name: "Test Camp",
            type: .campsite,
            sourceId: UUID()
        )
    )
    .padding()
}

#Preview("Annotation") {
    WaypointAnnotation(
        waypoint: RouteWaypoint(
            coordinate: .init(latitude: 0, longitude: 0),
            name: "Summit Peak",
            type: .summit,
            sourceId: UUID()
        ),
        isSelected: true,
        onTap: {}
    )
    .padding()
}
