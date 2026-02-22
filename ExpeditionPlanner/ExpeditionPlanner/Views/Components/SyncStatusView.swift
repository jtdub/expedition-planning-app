import SwiftUI

/// A view that displays the current CloudKit sync status
struct SyncStatusView: View {
    @ObservedObject var syncService: SyncStatusService

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            statusIcon
            Text(syncService.status.description)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
        .onTapGesture {
            syncService.refresh()
        }
    }

    @ViewBuilder private var statusIcon: some View {
        Image(systemName: syncService.status.icon)
            .font(.caption)
            .foregroundStyle(statusColor)
            .rotationEffect(.degrees(syncService.status == .syncing && isAnimating ? 360 : 0))
            .animation(
                syncService.status == .syncing
                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                    : .default,
                value: isAnimating
            )
            .onChange(of: syncService.status) { _, newStatus in
                isAnimating = newStatus == .syncing
            }
            .onAppear {
                isAnimating = syncService.status == .syncing
            }
    }

    private var statusColor: Color {
        switch syncService.status.color {
        case "green":
            return .green
        case "blue":
            return .blue
        case "red":
            return .red
        case "orange":
            return .orange
        default:
            return .secondary
        }
    }
}

/// A compact sync status indicator for toolbars
struct SyncStatusIndicator: View {
    @ObservedObject var syncService: SyncStatusService

    var body: some View {
        Image(systemName: syncService.status.icon)
            .foregroundStyle(indicatorColor)
            .help(syncService.status.description)
    }

    private var indicatorColor: Color {
        switch syncService.status.color {
        case "green":
            return .green
        case "blue":
            return .blue
        case "red":
            return .red
        case "orange":
            return .orange
        default:
            return .secondary
        }
    }
}

#Preview("Sync Status View") {
    SyncStatusView(syncService: SyncStatusService.shared)
        .padding()
}

#Preview("Sync Status Indicator") {
    SyncStatusIndicator(syncService: SyncStatusService.shared)
        .padding()
}
