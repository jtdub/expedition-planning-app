# Chaki — Expedition Planning App

A native iOS app for planning remote expeditions, built with SwiftUI and SwiftData with CloudKit sync. Chaki consolidates complex expedition planning workflows into a cohesive mobile experience.

## Features

- **Itinerary Planning** — Day-by-day schedules with elevation tracking, acclimatization visualization, route segments, and water sources
- **Gear Management** — Categorized lists with weight tracking, pack status (Critical/Suggested/Optional/Contingent)
- **Team Coordination** — Participants, group assignments, flight info, emergency contacts
- **Logistics** — Transport legs, accommodation, resupply points, permits, satellite devices
- **Budget Tracking** — Multi-currency expense tracking with conversion and summaries
- **Safety** — Risk assessments, insurance policies, historical climate data
- **PDF Export** — Generate comprehensive guidebook PDFs for your team
- **CSV Import** — Import gear lists and itineraries from spreadsheets
- **CloudKit Sync** — Seamless sync across iPhone and iPad via iCloud

## Requirements

- iOS 17+
- Xcode 15+
- Apple Developer account (for CloudKit)

## Getting Started

```bash
# Clone the repository
git clone https://github.com/jtdub/expedition-planning-app.git

# Open in Xcode
open ExpeditionPlanner/ExpeditionPlanner.xcodeproj
```

Build and run on an iOS 17+ simulator or device.

## Architecture

- **UI**: SwiftUI
- **Data**: SwiftData with CloudKit integration
- **Maps**: MapKit
- **Charts**: Swift Charts
- **Export**: PDFKit
- **Pattern**: MVVM with Repository pattern

No external package dependencies.

## Development

```bash
# Build
cd ExpeditionPlanner && xcodebuild -scheme Chaki -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
cd ExpeditionPlanner && xcodebuild -scheme Chaki -destination 'platform=iOS Simulator,name=iPhone 17' test

# Lint
cd ExpeditionPlanner && swiftlint lint --quiet
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
