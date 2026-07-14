import SwiftUI

struct CounterSettingsSave {
  let name: String?
  let buttonValues: [Int]
  let goal: Int?
  let resetPeriod: CounterResetPeriod
  let resetAnchorDay: Int
  let goalDirection: GoalDirection
}

struct CounterSettingsView: View {
  private static let maxQuickAddButtons = QuickAddConfiguration.presetCount

  let title: String
  let includeGoalAndReset: Bool
  let includeNameField: Bool
  let locksGoalDirection: Bool
  @State private var values: [Int]
  @State private var nameText: String
  @State private var hasGoal: Bool
  @State private var goalText: String
  @State private var resetPeriod: CounterResetPeriod
  @State private var resetAnchorDay: Int
  @State private var goalDirection: GoalDirection
  let onSave: (CounterSettingsSave) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var newValueText = ""

  init(
    title: String,
    values: [Int],
    onSave: @escaping (CounterSettingsSave) -> Void
  ) {
    self.title = title
    self.includeGoalAndReset = false
    self.includeNameField = false
    self.locksGoalDirection = false
    self._values = State(initialValue: Array(values.sorted().prefix(Self.maxQuickAddButtons)))
    self._nameText = State(initialValue: "")
    self._hasGoal = State(initialValue: false)
    self._goalText = State(initialValue: "")
    self._resetPeriod = State(initialValue: .daily)
    self._resetAnchorDay = State(initialValue: 1)
    self._goalDirection = State(initialValue: .countUp)
    self.onSave = onSave
  }

  init(
    title: String,
    values: [Int],
    counter: CustomCounter,
    onSave: @escaping (CounterSettingsSave) -> Void
  ) {
    self.title = title
    self.includeGoalAndReset = true
    self.includeNameField = true
    self.locksGoalDirection = false
    self._values = State(initialValue: Array(values.sorted().prefix(Self.maxQuickAddButtons)))
    self._nameText = State(initialValue: counter.name)
    self._hasGoal = State(initialValue: counter.effectiveGoal != nil)
    self._goalText = State(initialValue: counter.effectiveGoal.map(String.init) ?? "")
    self._resetPeriod = State(initialValue: counter.resetPeriod)
    self._resetAnchorDay = State(initialValue: counter.effectiveResetAnchorDay)
    self._goalDirection = State(initialValue: counter.goalDirection)
    self.onSave = onSave
  }

  var body: some View {
    NavigationStack {
      List {
        if includeNameField {
          Section("Name") {
            TextField("e.g. Protein", text: $nameText)
          }
        }

        Section {
          ForEach(values, id: \.self) { value in
            HStack {
              Text("+\(value)")
              Spacer()
              Button(role: .destructive) {
                values.removeAll { $0 == value }
              } label: {
                Image(systemName: "minus.circle.fill")
              }
              .buttonStyle(.plain)
            }
          }
        } header: {
          Text("Quick-add buttons")
        } footer: {
          Text("Up to \(Self.maxQuickAddButtons) preset buttons. Use the … button on the counter for custom amounts.")
        }

        if values.count < Self.maxQuickAddButtons {
          Section("Add button value") {
            HStack {
              TextField("e.g. 150", text: $newValueText)
                .keyboardType(.numberPad)
              Button("Add") {
                addValue()
              }
              .disabled(parsedNewValue == nil)
            }
          }
        }

        if includeGoalAndReset {
          goalAndResetSections
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave(
              CounterSettingsSave(
                name: includeNameField ? trimmedName : nil,
                buttonValues: Array(values.sorted().prefix(Self.maxQuickAddButtons)),
                goal: hasGoal ? parsedGoal : nil,
                resetPeriod: resetPeriod,
                resetAnchorDay: resetPeriod == .daily ? 1 : resetAnchorDay,
                goalDirection: locksGoalDirection ? .countDown : goalDirection
              )
            )
            dismiss()
          }
          .disabled(!canSave)
        }
      }
      .onChange(of: resetPeriod) { _, newPeriod in
        if newPeriod == .daily {
          resetAnchorDay = 1
        } else if newPeriod == .weekly, !(1...7).contains(resetAnchorDay) {
          resetAnchorDay = Calendar.current.firstWeekday
        } else if newPeriod == .monthly, !(1...28).contains(resetAnchorDay) {
          resetAnchorDay = 1
        }
      }
    }
  }

  @ViewBuilder
  private var goalAndResetSections: some View {
    Section("Goal") {
      Toggle("Set a target", isOn: $hasGoal)
      if hasGoal {
        TextField("Target amount", text: $goalText)
          .keyboardType(.numberPad)
      }

      if !locksGoalDirection {
        Picker("Direction", selection: $goalDirection) {
          ForEach(GoalDirection.allCases) { direction in
            Text(direction.label).tag(direction)
          }
        }
        Text(goalDirection.summary)
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        LabeledContent("Direction", value: GoalDirection.countDown.label)
        Text(GoalDirection.countDown.summary)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }

    Section("Reset period") {
      Picker("Period", selection: $resetPeriod) {
        ForEach(CounterResetPeriod.allCases) { period in
          Text(period.label).tag(period)
        }
      }

      if resetPeriod == .weekly {
        Picker("Resets on", selection: $resetAnchorDay) {
          ForEach(1...7, id: \.self) { weekday in
            Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
          }
        }
      }

      if resetPeriod == .monthly {
        Picker("Resets on day", selection: $resetAnchorDay) {
          ForEach(1...28, id: \.self) { day in
            Text("\(day)").tag(day)
          }
        }
      }
    }
  }

  private var navigationTitle: String {
    if includeNameField, !trimmedName.isEmpty {
      return "\(trimmedName) Settings"
    }
    return title
  }

  private var trimmedName: String {
    nameText.trimmingCharacters(in: .whitespaces)
  }

  private var canSave: Bool {
    if includeNameField, trimmedName.isEmpty {
      return false
    }
    if hasGoal, parsedGoal == nil {
      return false
    }
    return true
  }

  private var parsedNewValue: Int? {
    guard let value = Int(newValueText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }

  private var parsedGoal: Int? {
    guard let value = Int(goalText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }

  private func addValue() {
    guard values.count < Self.maxQuickAddButtons else { return }
    guard let value = parsedNewValue, !values.contains(value) else { return }
    values.append(value)
    values.sort()
    newValueText = ""
  }
}

#Preview {
  CounterSettingsView(title: "Protein Settings", values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
