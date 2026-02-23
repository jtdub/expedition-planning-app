import SwiftUI

struct ActivityTypePicker: View {
    @Binding var selection: ActivityType

    var body: some View {
        Picker("Activity Type", selection: $selection) {
            ForEach(ActivityType.allCases, id: \.self) { type in
                Label {
                    Text(type.rawValue)
                } icon: {
                    Image(systemName: type.icon)
                        .foregroundStyle(Color(type.color))
                }
                .tag(type)
            }
        }
    }
}

// MARK: - Activity Type Badge

struct ActivityTypeBadge: View {
    let activityType: ActivityType
    let style: BadgeStyle

    enum BadgeStyle {
        case compact
        case full
        case iconOnly
    }

    init(_ activityType: ActivityType, style: BadgeStyle = .compact) {
        self.activityType = activityType
        self.style = style
    }

    private var color: Color {
        Color(activityType.color)
    }

    var body: some View {
        switch style {
        case .compact:
            compactBadge
        case .full:
            fullBadge
        case .iconOnly:
            iconOnlyBadge
        }
    }

    private var compactBadge: some View {
        Label(activityType.rawValue, systemImage: activityType.icon)
            .font(.caption)
            .foregroundStyle(color)
    }

    private var fullBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: activityType.icon)
                .font(.body)

            Text(activityType.rawValue)
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color, in: Capsule())
    }

    private var iconOnlyBadge: some View {
        Image(systemName: activityType.icon)
            .foregroundStyle(color)
            .padding(8)
            .background(color.opacity(0.15), in: Circle())
    }
}

// MARK: - Activity Grid Picker

struct ActivityTypeGridPicker: View {
    @Binding var selection: ActivityType

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ActivityType.allCases, id: \.self) { type in
                Button {
                    selection = type
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color(type.color).opacity(selection == type ? 1 : 0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundStyle(selection == type ? .white : Color(type.color))
                        }

                        Text(type.rawValue)
                            .font(.caption2)
                            .foregroundStyle(selection == type ? Color(type.color) : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ActivityType = .fieldWork

        var body: some View {
            Form {
                Section("Standard Picker") {
                    ActivityTypePicker(selection: $selected)
                }

                Section("Badges") {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        HStack {
                            ActivityTypeBadge(type, style: .iconOnly)
                            ActivityTypeBadge(type, style: .compact)
                            Spacer()
                            ActivityTypeBadge(type, style: .full)
                        }
                    }
                }

                Section("Grid Picker") {
                    ActivityTypeGridPicker(selection: $selected)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    return PreviewWrapper()
}
