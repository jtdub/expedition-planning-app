import SwiftUI
import SwiftData

// MARK: - Lake Louise Score Entry View

struct LakeLouiseScoreEntryView: View {
    @Bindable var day: ItineraryDay

    @Environment(\.dismiss)
    private var dismiss

    @State private var headache: Int
    @State private var gastrointestinal: Int
    @State private var fatigue: Int
    @State private var dizziness: Int

    init(day: ItineraryDay) {
        self.day = day
        _headache = State(initialValue: day.llsHeadache ?? 0)
        _gastrointestinal = State(initialValue: day.llsGastrointestinal ?? 0)
        _fatigue = State(initialValue: day.llsFatigue ?? 0)
        _dizziness = State(initialValue: day.llsDizziness ?? 0)
    }

    private var total: Int {
        headache + gastrointestinal + fatigue + dizziness
    }

    private var diagnosis: LakeLouiseDiagnosis {
        LakeLouiseService.diagnose(
            headache: headache,
            gastrointestinal: gastrointestinal,
            fatigue: fatigue,
            dizziness: dizziness
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Summary Section
                Section {
                    diagnosisSummary
                } header: {
                    Text("Assessment")
                }

                // Symptom Scoring
                Section {
                    symptomPicker(
                        symptom: .headache,
                        value: $headache
                    )
                    symptomPicker(
                        symptom: .gastrointestinal,
                        value: $gastrointestinal
                    )
                    symptomPicker(
                        symptom: .fatigue,
                        value: $fatigue
                    )
                    symptomPicker(
                        symptom: .dizziness,
                        value: $dizziness
                    )
                } header: {
                    Text("Symptoms (0-3 each)")
                } footer: {
                    Text("0 = None, 1 = Mild, 2 = Moderate, 3 = Severe/Incapacitating")
                }

                // Recommendations
                if diagnosis != .notRecorded {
                    Section("Recommendations") {
                        ForEach(
                            LakeLouiseService.actionRecommendation(for: diagnosis),
                            id: \.self
                        ) { recommendation in
                            Label {
                                Text(recommendation)
                            } icon: {
                                Image(systemName: recommendationIcon(for: diagnosis))
                                    .foregroundStyle(diagnosis.color)
                            }
                        }
                    }
                }

                // Clear Button
                if day.hasLakeLouiseScore {
                    Section {
                        Button(role: .destructive) {
                            clearScore()
                        } label: {
                            Label("Clear Score", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Lake Louise Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveScore()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var diagnosisSummary: some View {
        VStack(spacing: 12) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(diagnosis.color.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(total) / 12.0)
                    .stroke(diagnosis.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(total)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("/ 12")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Diagnosis
            HStack {
                Image(systemName: diagnosis.icon)
                Text(diagnosis.rawValue)
            }
            .font(.headline)
            .foregroundStyle(diagnosis.color)

            // Interpretation
            Text(
                LakeLouiseService.totalScoreInterpretation(total, hasHeadache: headache > 0)
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func symptomPicker(
        symptom: LakeLouiseService.Symptom,
        value: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symptom.icon)
                    .foregroundStyle(LakeLouiseService.severityColor(for: value.wrappedValue))
                Text(symptom.rawValue)
                    .fontWeight(.medium)
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.headline)
                    .foregroundStyle(LakeLouiseService.severityColor(for: value.wrappedValue))
            }

            Picker(symptom.rawValue, selection: value) {
                ForEach(0...3, id: \.self) { score in
                    Text("\(score)").tag(score)
                }
            }
            .pickerStyle(.segmented)

            Text(symptom.scoreDescription(value.wrappedValue))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func recommendationIcon(for diagnosis: LakeLouiseDiagnosis) -> String {
        switch diagnosis {
        case .notRecorded: return "info.circle"
        case .noAMS: return "checkmark.circle"
        case .mildAMS: return "exclamationmark.circle"
        case .severeAMS: return "exclamationmark.octagon"
        }
    }

    // MARK: - Actions

    private func saveScore() {
        day.llsHeadache = headache
        day.llsGastrointestinal = gastrointestinal
        day.llsFatigue = fatigue
        day.llsDizziness = dizziness
        day.llsRecordedAt = Date()
    }

    private func clearScore() {
        headache = 0
        gastrointestinal = 0
        fatigue = 0
        dizziness = 0
        day.llsHeadache = nil
        day.llsGastrointestinal = nil
        day.llsFatigue = nil
        day.llsDizziness = nil
        day.llsRecordedAt = nil
    }
}

// MARK: - Lake Louise Score Badge

struct LakeLouiseScoreBadge: View {
    let day: ItineraryDay

    var body: some View {
        if day.hasLakeLouiseScore, let total = day.lakeLouiseTotal {
            let diagnosis = day.lakeLouiseDiagnosis

            HStack(spacing: 4) {
                Image(systemName: diagnosis.icon)
                Text("LLS: \(total)")
            }
            .font(.caption)
            .foregroundStyle(diagnosis.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(diagnosis.color.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Lake Louise Score Summary Card

struct LakeLouiseScoreSummaryCard: View {
    let day: ItineraryDay
    var onTap: (() -> Void)?

    var body: some View {
        if day.hasLakeLouiseScore {
            let diagnosis = day.lakeLouiseDiagnosis
            let total = day.lakeLouiseTotal ?? 0

            Button {
                onTap?()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Lake Louise Score", systemImage: "heart.text.square")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(total)/12")
                                .font(.headline)
                            Image(systemName: diagnosis.icon)
                        }
                        .foregroundStyle(diagnosis.color)
                    }

                    HStack(spacing: 12) {
                        scoreIndicator("H", value: day.llsHeadache ?? 0)
                        scoreIndicator("GI", value: day.llsGastrointestinal ?? 0)
                        scoreIndicator("F", value: day.llsFatigue ?? 0)
                        scoreIndicator("D", value: day.llsDizziness ?? 0)
                    }

                    Text(diagnosis.rawValue)
                        .font(.caption)
                        .foregroundStyle(diagnosis.color)

                    if let recordedAt = day.llsRecordedAt {
                        Text("Recorded: \(recordedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(diagnosis.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func scoreIndicator(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(LakeLouiseService.severityColor(for: value))
        }
        .frame(minWidth: 30)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([ItineraryDay.self, Expedition.self])
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        let day = ItineraryDay(dayNumber: 3, location: "High Camp")
        day.llsHeadache = 2
        day.llsGastrointestinal = 1
        day.llsFatigue = 1
        day.llsDizziness = 0
        day.llsRecordedAt = Date()
        container.mainContext.insert(day)
        return LakeLouiseScoreEntryView(day: day)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
