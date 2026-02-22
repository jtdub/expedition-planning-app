# Expedition Planning App

## Project Overview

A native iOS app for planning remote expeditions, built with SwiftUI and SwiftData with CloudKit sync. The app consolidates complex expedition planning workflows into a cohesive mobile experience.

**Target Platform**: iOS 17+ (iPhone primary, iPad adaptive)
**Architecture**: SwiftUI + SwiftData + CloudKit
**Pattern**: MVVM with Repository pattern

## Tech Stack

- **UI**: SwiftUI
- **Data**: SwiftData with CloudKit integration
- **Maps**: MapKit
- **Charts**: Swift Charts (for elevation visualization)
- **Export**: PDFKit

No external package dependencies for MVP.

## Project Structure

```
ExpeditionPlanner/
├── App/                    # App entry point, main ContentView
├── Models/                 # SwiftData models
├── Views/                  # SwiftUI views organized by feature
│   ├── Expeditions/
│   ├── Itinerary/
│   ├── Gear/
│   ├── Logistics/
│   ├── Budget/
│   └── Safety/
├── ViewModels/             # MVVM view models
├── Services/               # Data, export, currency, location services
├── Utilities/              # Extensions, constants, formatters
└── Resources/              # Assets, default templates
```

## Key Domain Concepts

Based on real expedition planning documents:

- **Expedition**: Top-level container with itinerary, gear, participants, contacts, permits, budget
- **ItineraryDay**: Day-by-day schedule with elevation tracking for acclimatization
- **GearItem**: Categorized gear with weight, priority, pack status (Critical/Suggested/Optional/Contingent)
- **Participant**: Team members with group assignments, flight info, contact details
- **ResupplyPoint**: Post offices, local contacts, services at waypoints
- **RiskAssessment**: Hazard identification with mitigation strategies

## Development Commands

```bash
# Open in Xcode
open ExpeditionPlanner/ExpeditionPlanner.xcodeproj

# Build from command line
cd ExpeditionPlanner && xcodebuild -scheme ExpeditionPlanner -destination 'generic/platform=iOS Simulator' build

# Run tests
cd ExpeditionPlanner && xcodebuild test -scheme ExpeditionPlanner -destination 'platform=iOS Simulator,name=iPhone 15'

# Run SwiftLint
swiftlint lint --config .swiftlint.yml
```

## Implementation Phases

1. **Foundation** ✅ COMPLETE: SwiftData + CloudKit setup, core models, expedition CRUD
2. **Itinerary**: Day-by-day editor, elevation tracking, acclimatization visualization
3. **Gear Management**: Categorized lists, weight calculator, pack status
4. **Logistics**: Participants, contacts, resupply points, permits
5. **Budget & Export**: Multi-currency tracking, PDF guidebook generation

## Code Quality

- SwiftLint configured via `.swiftlint.yml`
- Unit tests in `ExpeditionPlannerTests/`
- All code must pass `swiftlint lint` with 0 violations

## Data Model Relationships

```
Expedition
├── [ItineraryDay] - ordered by dayNumber
├── [GearList] - categorized gear items
├── [Participant] - with group assignments
├── [Contact] - emergency, local resources
├── [ResupplyPoint] - with local contacts
├── [Permit] - documents and deadlines
├── [BudgetItem] - categorized expenses
└── [RiskAssessment] - hazards and mitigations
```

## Conventions

- Use `@Model` macro for all SwiftData entities
- Views should be in feature-specific folders
- Use `Measurement<Unit>` for elevation (UnitLength) and weight (UnitMass)
- Coordinates use `CLLocationCoordinate2D`
- Currency amounts use `Decimal` for precision

## Example Data Sources

Reference files in `/examples/` directory:
- `Brooks Range Planner 2026.xlsx` - Multi-group scheduling, participant coordination
- `Alaska 2026 Gear.xlsx` - Comprehensive gear list with categories, weights, priorities
- `Peru Expedition Checklist.xlsx` - Simple checklist format
- `Field Schedule - Sibinacocha Expedition 2014_v2.0.xlsx` - Acclimatization schedule
- `Trip Planner - Alaska-Yukon Expedition.pdf` - Full guidebook with contacts, safety info
