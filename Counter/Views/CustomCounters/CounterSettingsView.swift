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
    self.defaultPresets = QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    self._values = State(initialValue: QuickAddConfiguration.normalizedPresets(values))
    self._nameText = State(initialValue: counter.name)
    self._unitText = State(initialValue: counter.unit)
    self._goalText = State(
      initialValue: counter.effectiveGoal.map(CounterFormatting.editingText) ?? ""
    )
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
          title: "Settings",
          isDoneEnabled: canSave,
          onDone: saveAndDismiss
        )

        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            SettingsLabeledField(label: "Title", text: $nameText)
            SettingsSectionDivider()

            goalAndResetContent

            SettingsLabeledField(
              label: "Unit",
              text: $unitText,
              placeholder: "e.g. kcal, g, $"
            )

            SettingsSectionDivider()

            quickAddSection
            colourSection

            if onDelete != nil {
              deleteSection
            }
          }
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.top, SettingsToken.sectionSpacing)
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

  @ViewBuilder
  private var goalAndResetContent: some View {
    SettingsLabeledField(
      label: "Target",
      text: $goalText,
      keyboardType: .decimalPad,
      placeholder: "0"
    )

    if hasActiveGoal {
      SettingsPickerRow(
        icon: .arrowUpToLine,
        label: "Direction",
        selection: $goalDirection,
        options: GoalDirection.allCases.map { ($0, $0.label) }
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
    }
  }

  private var colourSection: some View {
    Group {
      SettingsSectionDivider()

      SettingsSectionHeader(title: "Colour")

      SettingsColorSwatchGrid(selection: $paletteIndex)
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
        paletteIndex: paletteIndex
      )
    )
    dismiss()
  }
}

#Preview {
  CounterSettingsView(values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
