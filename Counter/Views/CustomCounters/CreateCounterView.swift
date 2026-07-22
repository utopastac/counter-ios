import SwiftUI
import SwiftData

struct CreateCounterView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false

  var onCreated: ((CustomCounter) -> Void)?

  @State private var template: CounterTemplate = .blank
  @State private var name = ""
  @State private var unit = ""
  @State private var goalText = ""
  @State private var goalDirection: GoalDirection = .countUp
  @State private var resetPeriod = AppAppearancePreference.defaultResetPeriod
  @State private var resetAnchorDay = AppAppearancePreference.defaultResetPeriod.defaultAnchorDay()
  @State private var paletteIndex = 0
  @State private var buttonValues: [Double] = QuickAddConfiguration.defaultCounterPresets

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: "Add new",
          trailingTitle: "Cancel",
          onDone: { dismiss() }
        )

        ScrollView {
          VStack(alignment: .leading, spacing: SettingsToken.sectionGap) {
            templateSection
            fieldsSection
            resetPeriodSection
            quickAddSection
            colourSection
          }
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.top, SpaceToken.u1)
          .padding(.bottom, SpaceToken.u2)
        }
        .settingsKeyboardDismissible()

        PrimaryCapsuleButton(title: "Create", isEnabled: canCreate) {
          createCounter()
        }
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u2)
        .padding(.bottom, SpaceToken.u2)
      }
      .background(colors.surfaceSheet)
      .toolbar(.hidden, for: .navigationBar)
      .onChange(of: resetPeriod) { _, newPeriod in
        resetAnchorDay = newPeriod.normalizedAnchorDay(resetAnchorDay)
      }
      .onChange(of: template) { _, newTemplate in
        applyTemplate(newTemplate)
      }
      .onAppear {
        resetPeriod = AppAppearancePreference.defaultResetPeriod
        resetAnchorDay = resetPeriod.defaultAnchorDay()
        paletteIndex = CustomCounter.nextPaletteIndex(forExistingCount: counters.count)
        applyTemplate(template)
      }
      .counterDesignSystemFromAppearancePreference()
    }
    .counterSheetPresentation()
  }

  private var templateSection: some View {
    SettingsPickerRow(
      icon: .rows3,
      label: "Template",
      selection: $template,
      options: CounterTemplate.allCases.map { ($0, $0.label) }
    )
  }

  private var fieldsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: SettingsToken.fieldSpacing) {
        SettingsLabeledField(label: "Title", text: $name, placeholder: CustomCounter.untitledName)

        SettingsLabeledField(
          label: "Unit",
          text: $unit,
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
      SettingsPresetGrid(
        values: $buttonValues,
        defaults: template.defaultPresets
      )
    }
  }

  private var colourSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SettingsSectionHeader(title: "Colour")
      SettingsColorSwatchGrid(selection: $paletteIndex)
    }
  }

  private var canCreate: Bool {
    CounterFormValidation.canSave(name: nil, goalText: goalText)
  }

  private var hasActiveGoal: Bool {
    parsedGoal != nil
  }

  private var parsedGoal: Double? {
    AmountInput.parsePositiveAmount(goalText)
  }

  private func applyTemplate(_ template: CounterTemplate) {
    name = template.defaultName
    unit = template.defaultUnit
    goalText = template.defaultGoal.map(CounterFormatting.editingText) ?? ""
    goalDirection = template.defaultGoalDirection
    buttonValues = QuickAddConfiguration.normalizedPresets(template.defaultPresets)
  }

  private func createCounter() {
    let counter = CustomCounter(
      name: CustomCounter.normalizedName(from: name),
      unit: CustomCounter.normalizedUnit(from: unit),
      buttonValues: QuickAddConfiguration.normalizedPresets(buttonValues),
      goal: parsedGoal,
      resetPeriod: resetPeriod,
      resetAnchorDay: resetPeriod.normalizedAnchorDay(resetAnchorDay),
      goalDirection: goalDirection,
      paletteIndex: paletteIndex,
      sortOrder: CustomCounter.nextSortOrder(forExisting: counters)
    )
    // Keep list insertion out of the sheet-dismiss animation transaction so underlay row
    // hit targets don't lag behind the visible layout (which made the new row open Create).
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      modelContext.insert(counter)
      WatchSyncEngine.publishCounterUpsert(counter)
      onCreated?(counter)
    }
    dismiss()
  }
}

#Preview {
  CreateCounterView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
