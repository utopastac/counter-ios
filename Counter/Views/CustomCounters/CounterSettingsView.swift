import SwiftUI

struct CounterSettingsSave {
  let name: String?
  let buttonValues: [Int]
  let goal: Int?
  let resetPeriod: CounterResetPeriod
  let resetAnchorDay: Int
  let goalDirection: GoalDirection
  let paletteIndex: Int?
}

struct CounterSettingsView: View {
  let title: String
  let includeGoalAndReset: Bool
  let includeNameField: Bool
  let locksGoalDirection: Bool
  let defaultPresets: [Int]
  @State private var values: [Int]
  @State private var nameText: String
  @State private var goalText: String
  @State private var resetPeriod: CounterResetPeriod
  @State private var resetAnchorDay: Int
  @State private var goalDirection: GoalDirection
  @State private var paletteIndex: Int
  let onSave: (CounterSettingsSave) -> Void
  let onPaletteChange: ((Int) -> Void)?
  let onDelete: (() -> Void)?

  @Environment(\.dismiss) private var dismiss
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @State private var showDeleteConfirmation = false

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  init(
    title: String,
    values: [Int],
    onSave: @escaping (CounterSettingsSave) -> Void
  ) {
    self.title = title
    self.includeGoalAndReset = false
    self.includeNameField = false
    self.locksGoalDirection = false
    self.defaultPresets = QuickAddConfiguration.defaultCounterPresets
    self._values = State(initialValue: QuickAddConfiguration.normalizedPresets(values))
    self._nameText = State(initialValue: "")
    self._goalText = State(initialValue: "")
    self._resetPeriod = State(initialValue: .daily)
    self._resetAnchorDay = State(initialValue: 1)
    self._goalDirection = State(initialValue: .countUp)
    self._paletteIndex = State(initialValue: 0)
    self.onSave = onSave
    self.onPaletteChange = nil
    self.onDelete = nil
  }

  init(
    title: String,
    values: [Int],
    counter: CustomCounter,
    onSave: @escaping (CounterSettingsSave) -> Void,
    onDelete: (() -> Void)? = nil,
    onPaletteChange: ((Int) -> Void)? = nil
  ) {
    self.title = title
    self.includeGoalAndReset = true
    self.includeNameField = true
    self.locksGoalDirection = false
    self.defaultPresets = QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    self._values = State(initialValue: QuickAddConfiguration.normalizedPresets(values))
    self._nameText = State(initialValue: counter.name)
    self._goalText = State(initialValue: counter.effectiveGoal.map(String.init) ?? "")
    self._resetPeriod = State(initialValue: counter.resetPeriod)
    self._resetAnchorDay = State(initialValue: counter.effectiveResetAnchorDay)
    self._goalDirection = State(initialValue: counter.goalDirection)
    self._paletteIndex = State(initialValue: counter.effectivePaletteIndex)
    self.onSave = onSave
    self.onPaletteChange = onPaletteChange
    self.onDelete = onDelete
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: navigationTitle,
          isDoneEnabled: canSave,
          onDone: saveAndDismiss
        )

        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            if includeNameField {
              SettingsLabeledField(label: "Title", text: $nameText)
              SettingsSectionDivider()
            }

            if includeGoalAndReset {
              goalAndResetContent
            }

            quickAddSection

            if includeNameField {
              colourSection
            }

            if onDelete != nil {
              deleteSection
            }
          }
          .padding(.horizontal, SheetToken.horizontal)
        }
      }
      .background(colors.surfaceSheet)
      .toolbar(.hidden, for: .navigationBar)
      .onChange(of: resetPeriod) { _, newPeriod in
        resetAnchorDay = newPeriod.normalizedAnchorDay(resetAnchorDay)
      }
      .onChange(of: paletteIndex) { _, newValue in
        onPaletteChange?(newValue)
      }
      .counterDesignSystemFromAppearancePreference()
    }
    .counterSheetPresentation()
    .alert("Delete?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        onDelete?()
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete \"\(displayName)\" and all of its entries. This can't be undone.")
    }
  }

  @ViewBuilder
  private var goalAndResetContent: some View {
    SettingsLabeledField(
      label: "Target",
      text: $goalText,
      keyboardType: .numberPad,
      placeholder: "0"
    )

    if hasActiveGoal, !locksGoalDirection {
      SettingsPickerRow(
        icon: .arrowUpToLine,
        label: "Direction",
        selection: $goalDirection,
        options: GoalDirection.allCases.map { ($0, $0.label) }
      )
    } else if hasActiveGoal, locksGoalDirection {
      SettingsStaticRow(
        icon: .arrowUpToLine,
        label: "Direction",
        value: GoalDirection.countDown.label
      )
    }

    SettingsSectionDivider()

    SettingsSectionHeader(title: "Reset period")

    SettingsPickerRow(
      icon: .calendar,
      label: "Period",
      selection: $resetPeriod,
      options: CounterResetPeriod.allCases.map { ($0, $0.label) }
    )

    if resetPeriod == .weekly {
      SettingsPickerRow(
        icon: .listRestart,
        label: "Resets on",
        selection: $resetAnchorDay,
        options: (1...7).map { ($0, Calendar.current.weekdaySymbols[$0 - 1]) }
      )
    }

    if resetPeriod == .monthly {
      SettingsPickerRow(
        icon: .listRestart,
        label: "Resets on",
        selection: $resetAnchorDay,
        options: (1...28).map { ($0, CounterResetPeriod.ordinalDay($0)) }
      )
    }

    SettingsSectionDivider()
  }

  private var quickAddSection: some View {
    Group {
      SettingsSectionHeader(title: "Quick add presets")

      SettingsPresetGrid(values: $values, defaults: defaultPresets)
        .padding(.bottom, SpaceToken.u2)
    }
  }

  private var colourSection: some View {
    Group {
      SettingsSectionDivider()

      SettingsSectionHeader(title: "Colour")

      SettingsColorSwatchGrid(selection: $paletteIndex)
        .padding(.bottom, SpaceToken.u2)
    }
  }

  private var deleteSection: some View {
    Group {
      SettingsSectionDivider()

      SettingsDestructiveRow(label: "Delete") {
        showDeleteConfirmation = true
      }
      .padding(.bottom, SpaceToken.u3)
    }
  }

  private var navigationTitle: String {
    if includeNameField {
      return "Settings"
    }
    return title
  }

  private var displayName: String {
    CustomCounter.normalizedName(from: trimmedName)
  }

  private var trimmedName: String {
    nameText.trimmingCharacters(in: .whitespaces)
  }

  private var hasActiveGoal: Bool {
    parsedGoal != nil
  }

  private var canSave: Bool {
    CounterFormValidation.canSave(name: includeNameField ? nameText : nil, goalText: goalText)
  }

  private var parsedGoal: Int? {
    AmountInput.parsePositiveInt(goalText)
  }

  private func saveAndDismiss() {
    onSave(
      CounterSettingsSave(
        name: includeNameField ? trimmedName : nil,
        buttonValues: QuickAddConfiguration.normalizedPresets(values),
        goal: parsedGoal,
        resetPeriod: resetPeriod,
        resetAnchorDay: resetPeriod.normalizedAnchorDay(resetAnchorDay),
        goalDirection: locksGoalDirection ? .countDown : goalDirection,
        paletteIndex: includeNameField ? paletteIndex : nil
      )
    )
    dismiss()
  }
}

#Preview {
  CounterSettingsView(title: "Protein Settings", values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
