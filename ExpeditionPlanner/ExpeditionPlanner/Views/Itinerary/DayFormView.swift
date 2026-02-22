import SwiftUI
import SwiftData

struct DayFormView: View {
    enum Mode {
        case create(expedition: Expedition)
        case edit(day: ItineraryDay)
    }

    @Environment(\.dismiss)
    private var dismiss

    let mode: Mode
    let modelContext: ModelContext

    @AppStorage("elevationUnit")
    private var elevationUnit: ElevationUnit = .meters

    @State private var viewModel: DayFormViewModel?

    // Location picker states
    @State private var showingStartLocationPicker = false
    @State private var showingEndLocationPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(viewModel?.title ?? "Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel?.save()
                        dismiss()
                    }
                    .disabled(viewModel?.canSave != true)
                }
            }
            .onAppear {
                if viewModel == nil {
                    let vmMode: DayFormViewModel.Mode
                    switch mode {
                    case .create(let expedition):
                        vmMode = .create(expedition: expedition)
                    case .edit(let day):
                        vmMode = .edit(day: day)
                    }
                    viewModel = DayFormViewModel(mode: vmMode, modelContext: modelContext)
                }
            }
        }
    }

    @ViewBuilder
    private func formContent(viewModel: DayFormViewModel) -> some View {
        Form {
            // Basic Info Section
            Section("Basic Info") {
                Stepper("Day \(viewModel.dayNumber)", value: Bindable(viewModel).dayNumber, in: 1...365)

                Toggle("Set Date", isOn: Bindable(viewModel).hasDate)

                if viewModel.hasDate {
                    DatePicker("Date", selection: Bindable(viewModel).date, displayedComponents: .date)
                }

                Picker("Activity Type", selection: Bindable(viewModel).activityType) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            }

            // Location Section
            Section("Location") {
                TextField("Start Location", text: Bindable(viewModel).startLocation)

                TextField("End Location", text: Bindable(viewModel).endLocation)

                TextField("General Location", text: Bindable(viewModel).location)
                    .foregroundStyle(.secondary)
            }

            // Location Coordinates Section
            Section {
                if let coord = viewModel.startCoordinate {
                    HStack {
                        Text("Start Coordinates")
                        Spacer()
                        Text(formatCoordinate(coord))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            showingStartLocationPicker = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                } else {
                    Button {
                        showingStartLocationPicker = true
                    } label: {
                        Label("Set Start Coordinates", systemImage: "mappin.and.ellipse")
                    }
                }

                if let coord = viewModel.endCoordinate {
                    HStack {
                        Text("End Coordinates")
                        Spacer()
                        Text(formatCoordinate(coord))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            showingEndLocationPicker = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                } else {
                    Button {
                        showingEndLocationPicker = true
                    } label: {
                        Label("Set End Coordinates", systemImage: "mappin.and.ellipse")
                    }
                }
            } header: {
                Text("Coordinates")
            } footer: {
                Text("Tap to pick location on map")
            }

            // Elevation Section
            Section {
                ElevationInputView(
                    label: "Start Elevation",
                    value: Binding(
                        get: { viewModel.startElevation(in: elevationUnit) },
                        set: { viewModel.setStartElevation($0, unit: elevationUnit) }
                    ),
                    unit: elevationUnit
                )

                ElevationInputView(
                    label: "End Elevation",
                    value: Binding(
                        get: { viewModel.endElevation(in: elevationUnit) },
                        set: { viewModel.setEndElevation($0, unit: elevationUnit) }
                    ),
                    unit: elevationUnit
                )

                ElevationInputView(
                    label: "High Point",
                    value: Binding(
                        get: { viewModel.highPoint(in: elevationUnit) },
                        set: { viewModel.setHighPoint($0, unit: elevationUnit) }
                    ),
                    unit: elevationUnit
                )

                ElevationInputView(
                    label: "Low Point",
                    value: Binding(
                        get: { viewModel.lowPoint(in: elevationUnit) },
                        set: { viewModel.setLowPoint($0, unit: elevationUnit) }
                    ),
                    unit: elevationUnit
                )

                // Show risk assessment
                if viewModel.acclimatizationRisk != .none {
                    HStack {
                        Image(systemName: viewModel.acclimatizationRisk.icon)
                            .foregroundStyle(viewModel.acclimatizationRisk.color)
                        Text(viewModel.acclimatizationRisk.rawValue)
                            .foregroundStyle(viewModel.acclimatizationRisk.color)
                        Spacer()
                        Text(viewModel.acclimatizationRisk.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Elevation")
            } footer: {
                elevationSummaryFooter(viewModel: viewModel)
            }

            // Distance & Timing Section
            Section("Distance & Timing") {
                HStack {
                    Text("Distance")
                    Spacer()
                    TextField(
                        "km",
                        value: Binding(
                            get: {
                                if let meters = viewModel.distanceMeters {
                                    return meters / 1000
                                }
                                return nil
                            },
                            set: {
                                viewModel.distanceMeters = $0.map { $0 * 1000 }
                            }
                        ),
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    Text("km")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Estimated Hours")
                    Spacer()
                    TextField(
                        "hours",
                        value: Bindable(viewModel).estimatedHours,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    Text("hrs")
                        .foregroundStyle(.secondary)
                }
            }

            // Description Section
            Section("Client Description") {
                TextEditor(text: Bindable(viewModel).clientDescription)
                    .frame(minHeight: 80)
            }

            Section("Guide Notes") {
                TextEditor(text: Bindable(viewModel).guideNotes)
                    .frame(minHeight: 80)
            }

            // Camp Section
            Section("Camp / Night") {
                Stepper(
                    "Night \(viewModel.nightNumber ?? 0)",
                    value: Binding(
                        get: { viewModel.nightNumber ?? 0 },
                        set: { viewModel.nightNumber = $0 > 0 ? $0 : nil }
                    ),
                    in: 0...365
                )

                TextField("Camp Name", text: Bindable(viewModel).campName)
            }
        }
        .sheet(isPresented: $showingStartLocationPicker) {
            LocationPickerView(
                coordinate: Bindable(viewModel).startCoordinate,
                locationName: Bindable(viewModel).startLocation
            )
        }
        .sheet(isPresented: $showingEndLocationPicker) {
            LocationPickerView(
                coordinate: Bindable(viewModel).endCoordinate,
                locationName: Bindable(viewModel).endLocation
            )
        }
    }

    @ViewBuilder
    private func elevationSummaryFooter(viewModel: DayFormViewModel) -> some View {
        if let gain = viewModel.elevationGain {
            Text("Elevation gain: +\(Int(gain))m")
        } else if let loss = viewModel.elevationLoss {
            Text("Elevation loss: -\(Int(loss))m")
        }
    }

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
    }
}

import CoreLocation

#Preview("Create") {
    do {
        let container = try ModelContainer(
            for: Expedition.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        let expedition = Expedition(name: "Test Expedition")
        container.mainContext.insert(expedition)

        return DayFormView(
            mode: .create(expedition: expedition),
            modelContext: container.mainContext
        )
    } catch {
        return Text("Failed to create preview")
    }
}
