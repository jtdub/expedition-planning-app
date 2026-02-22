# Implementation Plan: Expedition Planning & Logistics iOS App

## Executive Summary

Build a native iOS app for planning remote expeditions, consolidating the workflows from existing spreadsheet-based planning (Brooks Range Planner, Alaska Gear Lists, Peru Expedition Checklist, Sibinacocha Field Schedule) into a cohesive mobile experience with iCloud sync.

## Architecture

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI (iOS 17+) |
| Data Persistence | SwiftData with CloudKit |
| Architecture | MVVM with Repository pattern |
| Maps | MapKit |
| Charts | Swift Charts |
| PDF Export | PDFKit |
| Target | iPhone primary, iPad adaptive |

## Data Model Overview

```
Expedition (root)
├── ItineraryDay[] - day-by-day schedule with elevation
├── GearList[] - categorized gear with weights
├── Participant[] - team members with groups
├── Contact[] - emergency/local contacts
├── ResupplyPoint[] - waypoints with services
├── Permit[] - documents and deadlines
├── BudgetItem[] - expenses with currency
├── RiskAssessment[] - hazards and mitigations
└── MealPlan[] - daily meal schedules
```

## Implementation Phases

### Phase 1: Foundation
**GitHub Issue**: #1

- Xcode project setup with SwiftUI + SwiftData + CloudKit
- CloudKit container and entitlements configuration
- Core data models implementation
- Expedition list and detail view scaffold
- Basic CRUD with sync indicators

**Deliverable**: Working app skeleton with iCloud sync

---

### Phase 2: Itinerary & Acclimatization
**GitHub Issue**: #2

- Day-by-day itinerary editor
- Elevation tracking (meters/feet)
- Elevation profile chart (Swift Charts)
- Activity type color coding
- Acclimatization warnings (>500m/day above 3000m)
- Dual description fields (client/guide views)

**Deliverable**: Complete itinerary management with altitude visualization

---

### Phase 3: Gear Management
**GitHub Issue**: #3

- 13-category gear organization
- Priority levels (Critical/Suggested/Optional/Contingent)
- Weight tracking with running totals
- Pack status checkboxes
- Pre/post-hike comments
- Template import

**Deliverable**: Full gear list management matching Alaska 2026 Gear structure

---

### Phase 4: Logistics & Safety
**GitHub Issues**: #4, #6

- Participant roster with group assignments
- Contact directory (searchable, categorized)
- Permit tracker with deadlines
- Resupply point directory with map
- Risk assessment module
- Emergency contacts quick access

**Deliverable**: Complete logistics and safety management

---

### Phase 5: Budget & Export
**GitHub Issue**: #5

- Multi-currency budget tracking
- Exchange rate integration
- Receipt capture
- PDF guidebook generation
- Template system (save/import/export)

**Deliverable**: Budget management and professional PDF export

---

### Bonus: Meal Planning
**GitHub Issue**: #7

- Daily meal scheduler
- Recipe links
- Ingredient lists
- Calorie tracking (optional)

**Deliverable**: Meal planning integration

---

## File Structure

```
ExpeditionPlanner/
├── ExpeditionPlannerApp.swift
├── ContentView.swift
├── Models/
│   ├── Expedition.swift
│   ├── ItineraryDay.swift
│   ├── GearItem.swift
│   ├── Participant.swift
│   ├── Contact.swift
│   ├── ResupplyPoint.swift
│   ├── Permit.swift
│   ├── BudgetItem.swift
│   ├── RiskAssessment.swift
│   └── MealPlan.swift
├── Views/
│   ├── Expeditions/
│   ├── Itinerary/
│   ├── Gear/
│   ├── Logistics/
│   ├── Budget/
│   └── Safety/
├── ViewModels/
├── Services/
│   ├── DataService.swift
│   ├── ExportService.swift
│   ├── CurrencyService.swift
│   └── LocationService.swift
├── Utilities/
└── Resources/
    └── DefaultGearTemplates.json
```

## Key Features Summary

| Feature | Source Reference |
|---------|------------------|
| Multi-group scheduling | Brooks Range Planner 2026.xlsx |
| Elevation/acclimatization | Sibinacocha Expedition schedule |
| 13-category gear lists | Alaska 2026 Gear.xlsx |
| Weight tracking | Alaska 2026 Gear.xlsx |
| Priority system | Alaska 2026 Gear.xlsx |
| Participant coordination | Brooks Range Planner 2026.xlsx |
| Contact directory | Alaska-Yukon Expedition PDF |
| Resupply points | Alaska-Yukon Expedition PDF |
| Risk assessment | Alaska-Yukon Expedition PDF |
| Meal planning | Wind River Meal Plan 2023.xlsx |

## Testing Strategy

1. **Unit Tests**: Data model validation, currency conversion, elevation calculations
2. **UI Tests**: Navigation flows, form submissions, data persistence
3. **Manual Testing**:
   - Create expedition matching Brooks Range Planner structure
   - Import gear list matching Alaska 2026 Gear format
   - Generate PDF export and compare to Alaska-Yukon guidebook
4. **Device Testing**: iPhone (primary), iPad (adaptive layout)
5. **Sync Testing**: Verify CloudKit sync between multiple devices

## Success Criteria

- [ ] All 5 phases implemented and functional
- [ ] iCloud sync working reliably
- [ ] PDF export quality matches reference guidebook
- [ ] Can replicate any of the example expedition documents in the app
- [ ] App Store ready (no crashes, good performance)

## Dependencies

**Internal**: None (all Apple frameworks)

**External APIs** (Phase 5):
- Exchange rate API for currency conversion (e.g., exchangerate-api.com free tier)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| CloudKit sync complexity | Start with simple models, add relationships incrementally |
| PDF generation quality | Use PDFKit with custom drawing, test early |
| Large gear lists performance | Use lazy loading, pagination |
| Offline/online conflict | SwiftData handles most cases; add manual conflict UI if needed |
