# Chaki — Expedition Planning App

## Project Overview

A native iOS app for planning remote expeditions, built with SwiftUI and SwiftData with CloudKit sync. The app consolidates complex expedition planning workflows into a cohesive mobile experience.

**Target Platform**: iOS 17+ (iPhone primary, iPad adaptive)
**Architecture**: SwiftUI + SwiftData + CloudKit
**Pattern**: MVVM with Repository pattern
**Scope**: Pre-trip planning only. Field-use (during expedition) and post-trip features are out of scope.

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
│   ├── Budget/
│   ├── Components/         # Shared/reusable UI components
│   ├── Expeditions/
│   ├── Gear/
│   ├── Itinerary/
│   ├── Logistics/
│   │   ├── Accommodation/
│   │   ├── Contacts/
│   │   ├── Participants/
│   │   ├── Permits/
│   │   ├── Resupply/
│   │   ├── SatelliteDevice/
│   │   └── Transport/
│   ├── Map/
│   ├── Safety/
│   ├── Settings/
│   └── Weather/
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
- **TransportLeg**: Travel segments between locations (flights, buses, boats, etc.)
- **Accommodation**: Lodging at waypoints (hotels, campsites, huts)
- **SatelliteDevice**: Satellite communicators and tracking devices
- **InsurancePolicy**: Travel/evacuation insurance details
- **Shelter**: Tents, tarps, and shelter equipment
- **HistoricalClimate**: Historical weather data for route planning

## Development Commands

```bash
# Open in Xcode
open ExpeditionPlanner/ExpeditionPlanner.xcodeproj

# Build from command line
cd ExpeditionPlanner && xcodebuild -scheme Chaki -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
cd ExpeditionPlanner && xcodebuild -scheme Chaki -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run SwiftLint
cd ExpeditionPlanner && swiftlint lint --quiet
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push and PR to main:
- **SwiftLint**: Enforces code style with `--strict` flag
- **Build**: Compiles for iOS Simulator
- **Test**: Runs all unit tests and uploads results as artifacts

## Implementation Phases

1. **Foundation** ✅ COMPLETE: SwiftData + CloudKit setup, core models, expedition CRUD
2. **Itinerary** ✅ COMPLETE: Day-by-day editor, elevation tracking, acclimatization visualization
3. **Gear Management** ✅ COMPLETE: Categorized lists, weight calculator, pack status
4. **Logistics** ✅ COMPLETE: Participants, contacts, resupply points, permits, transport, accommodation, satellite devices
5. **Budget & Export** ✅ COMPLETE: Multi-currency tracking, PDF guidebook generation

> **Safety Module**: Risk assessments, insurance policies, and historical climate data are implemented. Field-use features (Lake Louise AMS scoring, live weather) were removed as out of scope.

## Code Quality

- SwiftLint configured via `ExpeditionPlanner/.swiftlint.yml`
- Unit tests in `ExpeditionPlanner/ExpeditionPlannerTests/` (185 tests)
- All code must pass `swiftlint lint` with 0 violations
- CI runs lint and tests on every PR

## Data Model Relationships

```
Expedition
├── [ItineraryDay] - ordered by dayNumber
├── [GearItem] - categorized gear with weight/priority
├── [Participant] - with group assignments
├── [Contact] - emergency, local resources
├── [ResupplyPoint] - with local contacts
├── [Permit] - documents and deadlines
├── [BudgetItem] - categorized expenses
├── [RiskAssessment] - hazards and mitigations
├── [InsurancePolicy] - travel/evacuation coverage
├── [TransportLeg] - travel segments between locations
├── [Accommodation] - lodging at waypoints
├── [SatelliteDevice] - communicators and trackers
├── [Shelter] - tents, tarps, shelter equipment
└── [HistoricalClimate] - historical weather data
```

## Conventions

- Use `@Model` macro for all SwiftData entities
- All SwiftData model properties must have default values OR be optional (CloudKit requirement)
- All SwiftData relationships must be optional (CloudKit requirement)
- Use fully qualified enum defaults in @Model classes (e.g., `ExpeditionStatus.planning` not `.planning`)
- Views should be in feature-specific folders
- Use `Measurement<Unit>` for elevation (UnitLength) and weight (UnitMass)
- Coordinates use `CLLocationCoordinate2D`
- Currency amounts use `Decimal` for precision
- Use OSLog for logging, not print statements

## Example Data Sources

Reference files in `/examples/` directory:
- `Brooks Range Planner 2026.xlsx` - Multi-group scheduling, participant coordination
- `Alaska 2026 Gear.xlsx` - Comprehensive gear list with categories, weights, priorities
- `Peru Expedition Checklist.xlsx` - Simple checklist format
- `Field Schedule - Sibinacocha Expedition 2014_v2.0.xlsx` - Acclimatization schedule
- `Trip Planner - Alaska-Yukon Expedition.pdf` - Full guidebook with contacts, safety info
