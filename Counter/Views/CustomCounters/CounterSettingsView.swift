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
  let historyAverageActiveDaysOnlyRaw: String?
  let historyPerPeriodRaw: String?
  let headerDisplayRaw: String?
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
  @State private var historyAverageActiveDaysChoice: HistoryAverageActiveDaysChoice
  @State private var historyPerPeriodChoice: HistoryPerPeriodChoice
  @State private var headerDisplayChoice: CounterHeaderDisplayChoice
  let onSave: (CounterSettingsSave) -> Void
  let onPaletteChange: ((Int) -> Void)?
  let onDelete: (() -> Void)?
  private let kind: JournalKind

  @Environment(\.dismiss) private var dismiss
  @State private var showDeleteConfirmation = false
  @State private var didDelete = false

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
      historyAverageActiveDaysChoice: counter.historyAverageActiveDaysOnlyChoice,
      historyPerPeriodChoice: counter.historyPerPeriodChoice,
      headerDisplayChoice: counter.headerDisplayChoice,
      kind: counter.kind,
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
    historyAverageActiveDaysChoice: HistoryAverageActiveDaysChoice = .default,
    historyPerPeriodChoice: HistoryPerPeriodChoice = .default,
    headerDisplayChoice: CounterHeaderDisplayChoice = .default,
    kind: JournalKind = .number,
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
    self._historyAverageActiveDaysChoice = State(initialValue: historyAverageActiveDaysChoice)
    self._historyPerPeriodChoice = State(initialValue: historyPerPeriodChoice)
    self._headerDisplayChoice = State(initialValue: headerDisplayChoice)
    self.kind = kind
    self.onSave = onSave
    self.onPaletteChange = onPaletteChange
    self.onDelete = onDelete
  }

  var body: some View {
    NavigationStack {
      CounterSheetScroll(title: "Settings") {
        fieldsSection
        generalSection
        if kind == .number {
          quickAddSection
        }
        colourSection

        if onDelete != nil {
          deleteSection
        }

        Color.clear.frame(height: SpaceToken.u4)
      }
      .settingsKeyboardDismissible()
      .toolbar(.hidden, for: .navigationBar)
      .onChange(of: resetPeriod) { _, newPeriod in
        resetAnchorDay = newPeriod.normalizedAnchorDay(resetAnchorDay)
      }
      .onChange(of: paletteIndex) { _, newValue in
        onPaletteChange?(newValue)
      }
      .onDisappear {
        // Swipe-to-dismiss replaces the old Done button — persist when the form is valid.
        guard !didDelete, canSave else { return }
        save()
      }
      .interactiveDismissDisabled(!canSave)
      .counterDesignSystemFromAppearancePreference()
    }
    .counterSheetPresentation()
    .alert("Delete?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        didDelete = true
        onDelete?()
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete \"\(displayName)\" and all of its entries. This can't be undone.")
    }
  }

  private var fieldsSection: some View {
    VStack(alignment: .leading, spacing: SettingsToken.rowGap) {
      VStack(alignment: .leading, spacing: SettingsToken.fieldSpacing) {
        SettingsLabeledField(label: "Title", text: $nameText)

        if kind == .number {
          SettingsLabeledField(
            label: "Units",
            text: $unitText,
            placeholder: "e.g. kcal, g, $"
          )
        }

        SettingsLabeledField(
          label: kind.requiresCap ? "Limit" : "Target",
          text: $goalText,
          keyboardType: .decimalPad,
          placeholder: "0"
        )
      }

      if kind == .number, hasActiveGoal {
        SettingsPickerRow(
          label: "Direction",
          selection: $goalDirection,
          options: GoalDirection.allCases.map { ($0, $0.label) }
        )
      }
    }
    .padding(.horizontal, SheetToken.horizontal)
  }

  /// Display, reset, ring, and history controls — one flat section, no subheadings.
  private var generalSection: some View {
    VStack(alignment: .leading, spacing: SettingsToken.rowGap) {
      SettingsPickerRow(
        label: "Header display",
        selection: $headerDisplayChoice,
        options: CounterHeaderDisplayChoice.allCases.map { ($0, $0.label) }
      )

      SettingsPickerRow(
        label: "Reset period",
        selection: $resetPeriod,
        options: CounterResetPeriod.allCases.map { ($0, $0.label) }
      )

      if resetPeriod == .weekly {
        SettingsPickerRow(
          label: "Resets on",
          selection: $resetAnchorDay,
          options: (1...7).map { ($0, Calendar.current.weekdaySymbols[$0 - 1]) }
        )
      }

      if resetPeriod == .monthly {
        SettingsPickerRow(
          label: "Resets on",
          selection: $resetAnchorDay,
          options: (1...28).map { ($0, CounterResetPeriod.ordinalDay($0)) }
        )
      }

      if resetPeriod == .yearly {
        SettingsPickerRow(
          label: "Resets in",
          selection: $resetAnchorDay,
          options: (1...12).map { ($0, Calendar.current.monthSymbols[$0 - 1]) }
        )
      }

      SettingsPickerRow(
        label: "Ring width",
        selection: $ringWidthChoice,
        options: ProgressRingWidthChoice.allCases.map { ($0, $0.label) }
      )

      SettingsPickerRow(
        label: "Ring glow",
        selection: $ringGlowChoice,
        options: ProgressRingGlowChoice.allCases.map { ($0, $0.label) }
      )

      SettingsPickerRow(
        label: "Daily average",
        selection: $historyPerPeriodChoice,
        options: HistoryPerPeriodChoice.allCases.map { ($0, $0.label) }
      )

      SettingsPickerRow(
        label: "Active days only",
        selection: $historyAverageActiveDaysChoice,
        options: HistoryAverageActiveDaysChoice.allCases.map { ($0, $0.label) }
      )
    }
    .padding(.horizontal, SheetToken.horizontal)
  }

  private var quickAddSection: some View {
    VStack(alignment: .leading, spacing: SettingsToken.rowGap) {
      SettingsSectionHeader(title: "Quick add presets")
      SettingsPresetGrid(values: $values, defaults: defaultPresets)
    }
    .padding(.horizontal, SheetToken.horizontal)
  }

  private var colourSection: some View {
    VStack(alignment: .leading, spacing: SettingsToken.rowGap) {
      SettingsSectionHeader(title: "Colour")
      SettingsColorSwatchGrid(selection: $paletteIndex)
    }
    .padding(.horizontal, SheetToken.horizontal)
  }

  private var deleteSection: some View {
    VStack(alignment: .leading, spacing: SettingsToken.rowGap) {
      SettingsDivider()
      SettingsDestructiveRow(label: "Delete") {
        showDeleteConfirmation = true
      }
    }
    .padding(.horizontal, SheetToken.horizontal)
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
    CounterFormValidation.canSave(name: nameText, goalText: goalText, requiresCap: kind.requiresCap)
  }

  private var parsedGoal: Double? {
    AmountInput.parsePositiveAmount(goalText)
  }

  private func save() {
    onSave(
      CounterSettingsSave(
        name: trimmedName,
        buttonValues: QuickAddConfiguration.normalizedPresets(values),
        goal: parsedGoal,
        unit: kind == .number ? CustomCounter.normalizedUnit(from: unitText) : "",
        resetPeriod: resetPeriod,
        resetAnchorDay: resetPeriod.normalizedAnchorDay(resetAnchorDay),
        goalDirection: kind.requiresCap ? .countUp : goalDirection,
        paletteIndex: paletteIndex,
        progressRingWidthRaw: ringWidthChoice.storedRaw,
        progressRingGlowRaw: ringGlowChoice.storedRaw,
        historyAverageActiveDaysOnlyRaw: historyAverageActiveDaysChoice.storedRaw,
        historyPerPeriodRaw: historyPerPeriodChoice.storedRaw,
        headerDisplayRaw: headerDisplayChoice.storedRaw
      )
    )
  }
}

#Preview {
  CounterSettingsView(values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
