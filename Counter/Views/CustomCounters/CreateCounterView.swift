import SwiftUI
import SwiftData

struct CreateCounterView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false

  var onCreated: ((CustomCounter) -> Void)?

  @State private var name = ""
  @State private var goalText = ""
  @State private var goalDirection: GoalDirection = .countUp
  @State private var resetPeriod: CounterResetPeriod = .daily
  @State private var resetAnchorDay = Calendar.current.firstWeekday
  @State private var paletteIndex = 0

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: "New counter",
          trailingTitle: "Cancel",
          onDone: { dismiss() }
        )

        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            SettingsLabeledField(label: "Title", text: $name, placeholder: "e.g. Protein")
            SettingsSectionDivider()

            goalAndResetContent
            colourSection
          }
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.bottom, SpaceToken.u2)
        }

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
      .onAppear {
        paletteIndex = CustomCounter.nextPaletteIndex(forExistingCount: counters.count)
      }
      .counterDesignSystemFromAppearancePreference()
    }
    .counterSheetPresentation()
  }

  @ViewBuilder
  private var goalAndResetContent: some View {
    SettingsLabeledField(
      label: "Target",
      text: $goalText,
      keyboardType: .numberPad,
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
  }

  private var colourSection: some View {
    Group {
      SettingsSectionDivider()

      SettingsSectionHeader(title: "Colour")

      SettingsColorSwatchGrid(selection: $paletteIndex)
    }
  }

  private var canCreate: Bool {
    CounterFormValidation.canSave(name: name, goalText: goalText)
  }

  private var hasActiveGoal: Bool {
    parsedGoal != nil
  }

  private var parsedGoal: Int? {
    AmountInput.parsePositiveInt(goalText)
  }

  private func createCounter() {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }

    let counter = CustomCounter(
      name: trimmed,
      goal: parsedGoal,
      resetPeriod: resetPeriod,
      resetAnchorDay: resetPeriod.normalizedAnchorDay(resetAnchorDay),
      goalDirection: goalDirection,
      paletteIndex: paletteIndex
    )
    modelContext.insert(counter)
    onCreated?(counter)
    dismiss()
  }
}

#Preview {
  CreateCounterView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
