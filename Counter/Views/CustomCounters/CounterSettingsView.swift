import SwiftUI

struct CounterSettingsSave {
  let name: String?
  let buttonValues: [Double]
  let goal: Double?
  let unit: String
  let resetPeriod: CounterResetPeriod
  let resetAnchorDay: Int
  let goalDirection: GoalDirection
  let paletteIndex: Int?
  let progressRingWidthRaw: String?
  let progressRingGlowRaw: String?
}

struct CounterSettingsView: View {
  let defaultPresets: [Double]
  @State private var values: [Double]
  @State private var nameText: String
  @State private var unitText: String
  @State private var goalText: String
  @State private var resetPeriod: CounterResetPeriod
  @State private var resetAnchorDay: Int
  @State private var goalDirection: GoalDirection
  @State private var paletteIndex: Int
  @State private var ringWidthChoice: ProgressRingWidthChoice
  @State private var ringGlowChoice: ProgressRingGlowChoice
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
    values: [Double],
    counter: CustomCounter,
    onSave: @escaping (CounterSettingsSave) -> Void,
    onDelete: (() -> Void)? = nil,
    onPaletteChange: ((Int) -> Void)? = nil
  ) {
    self.init(
      values: values,
      name: counter.name,
      unit: counter.unit,
      goalText: counter.effectiveGoal.map(CounterFormatting.editingText) ?? "",
      resetPeriod: counter.resetPeriod,
      resetAnchorDay: counter.effectiveResetAnchorDay,
      goalDirection: counter.goalDirection,
      paletteIndex: counter.effectivePaletteIndex,
      ringWidthChoice: counter.progressRingWidthChoice,
      ringGlowChoice: counter.progressRingGlowChoice,
      defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name),
      onSave: onSave,
      onDelete: onDelete,
      onPaletteChange: onPaletteChange
    )
  }

  init(
    values: [Double],
    name: String,
    unit: String,
    goalText: String,
    resetPeriod: CounterResetPeriod,
    resetAnchorDay: Int,
    goalDirection: GoalDirection,
    paletteIndex: Int,
    ringWidthChoice: ProgressRingWidthChoice = .default,
    ringGlowChoice: ProgressRingGlowChoice = .default,
    defaultPresets: [Double],
    onSave: @escaping (CounterSettingsSave) -> Void,
    onDelete: (() -> Void)? = nil,
    onPaletteChange: ((Int) -> Void)? = nil
  ) {
    self.defaultPresets = defaultPresets
    self._values = State(initialValue: QuickAddConfiguration.normalizedPresets(values))
    self._nameText = State(initialValue: name)
    self._unitText = State(initialValue: unit)
    self._goalText = State(initialValue: goalText)
    self._resetPeriod = State(initialValue: resetPeriod)
    self._resetAnchorDay = State(initialValue: resetAnchorDay)
    self._goalDirection = State(initialValue: goalDirection)
    self._paletteIndex = State(initialValue: CustomCounter.normalizedPaletteIndex(paletteIndex))
    self._ringWidthChoice = State(initialValue: ringWidthChoice)
    self._ringGlowChoice = State(initialValue: ringGlowChoice)
    self.onSave = onSave
    self.onPaletteChange = onPaletteChange
    self.onDelete = onDelete
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: "Settings",
          isDoneEnabled: canSave,
          onDone: saveAndDismiss
        )

        ScrollView {
          VStack(alignment: .leading, spacing: SettingsToken.sectionGap) {
            fieldsSection
            resetPeriodSection
            quickAddSection
            colourSection
            ringSection

            if onDelete != nil {
              deleteSection
            }
          }
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.top, SpaceToken.u1)
          .padding(.bottom, SpaceToken.u4)
        }
        .settingsKeyboardDismissible()
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

  private var fieldsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: SettingsToken.fieldSpacing) {
        SettingsLabeledField(label: "Title", text: $nameText)

        SettingsLabeledField(
          label: "Units",
          text: $unitText,
          placeholder: "e.g. kcal, g, $"
        )

        SettingsLabeledField(
          label: "Target",
          text: $goalText,
          keyboardType: .decimalPad,
          placeholder: "0"
        )
      }

      if hasActiveGoal {
        SettingsPickerRow(
          icon: .arrowUpToLine,
          label: "Direction",
          selection: $goalDirection,
          options: GoalDirection.allCases.map { ($0, $0.label) }
        )
        .padding(.top, SpaceToken.x1)
      }
    }
  }

  private var resetPeriodSection: some View {
    VStack(alignment: .leading, spacing: 0) {
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

      if resetPeriod == .yearly {
        SettingsPickerRow(
          icon: .listRestart,
          label: "Resets in",
          selection: $resetAnchorDay,
          options: (1...12).map { ($0, Calendar.current.monthSymbols[$0 - 1]) }
        )
      }
    }
  }

  private var quickAddSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SettingsSectionHeader(title: "Quick add presets")
      SettingsPresetGrid(values: $values, defaults: defaultPresets)
    }
  }

  private var colourSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SettingsSectionHeader(title: "Colour")
      SettingsColorSwatchGrid(selection: $paletteIndex)
    }
  }

  private var ringSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SettingsSectionHeader(title: "Ring")

      SettingsPickerRow(
        icon: .ringDot,
        label: "Width",
        selection: $ringWidthChoice,
        options: ProgressRingWidthChoice.allCases.map { ($0, $0.label) }
      )

      SettingsPickerRow(
        icon: .sparkle,
        label: "Glow",
        selection: $ringGlowChoice,
        options: ProgressRingGlowChoice.allCases.map { ($0, $0.label) }
      )
    }
  }

  private var deleteSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SettingsDivider()
      SettingsDestructiveRow(label: "Delete") {
        showDeleteConfirmation = true
      }
    }
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
    CounterFormValidation.canSave(name: nameText, goalText: goalText)
  }

  private var parsedGoal: Double? {
    AmountInput.parsePositiveAmount(goalText)
  }

  private func saveAndDismiss() {
    onSave(
      CounterSettingsSave(
        name: trimmedName,
        buttonValues: QuickAddConfiguration.normalizedPresets(values),
        goal: parsedGoal,
        unit: CustomCounter.normalizedUnit(from: unitText),
        resetPeriod: resetPeriod,
        resetAnchorDay: resetPeriod.normalizedAnchorDay(resetAnchorDay),
        goalDirection: goalDirection,
        paletteIndex: paletteIndex,
        progressRingWidthRaw: ringWidthChoice.storedRaw,
        progressRingGlowRaw: ringGlowChoice.storedRaw
      )
    )
    dismiss()
  }
}

#Preview {
  CounterSettingsView(values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
