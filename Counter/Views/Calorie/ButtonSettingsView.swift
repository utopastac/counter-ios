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
  private static let maxQuickAddButtons = QuickAddConfiguration.presetCount

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
  @State private var editingPreset: PresetEditItem?
  @State private var isAddingPreset = false
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
    self._values = State(initialValue: Array(values.sorted().prefix(Self.maxQuickAddButtons)))
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
    self.defaultPresets = counter.name.lowercased() == "calories"
      ? QuickAddConfiguration.defaultCaloriePresets
      : QuickAddConfiguration.defaultCounterPresets
    self._values = State(initialValue: Array(values.sorted().prefix(Self.maxQuickAddButtons)))
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
        if newPeriod == .daily {
          resetAnchorDay = 1
        } else if newPeriod == .weekly, !(1...7).contains(resetAnchorDay) {
          resetAnchorDay = Calendar.current.firstWeekday
        } else if newPeriod == .monthly, !(1...28).contains(resetAnchorDay) {
          resetAnchorDay = 1
        }
      }
      .onChange(of: paletteIndex) { _, newValue in
        onPaletteChange?(newValue)
      }
      .sheet(item: $editingPreset) { item in
        AmountEntrySheet(
          title: "Edit preset",
          actionTitle: "Save",
          initialText: String(item.value)
        ) { newValue in
          replacePreset(old: item.value, with: newValue)
        }
      }
      .sheet(isPresented: $isAddingPreset) {
        AmountEntrySheet(
          title: "Add preset",
          actionTitle: "Add"
        ) { newValue in
          addPreset(newValue)
        }
      }
      .counterDesignSystemFromAppearancePreference()
    }
    .counterSheetPresentation()
    .alert("Delete counter?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        onDelete?()
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete \"\(trimmedName)\" and all of its entries. This can't be undone.")
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
        options: (1...28).map { ($0, ordinalDay($0)) }
      )
    }

    SettingsSectionDivider()
  }

  private var quickAddSection: some View {
    Group {
      SettingsSectionHeader(title: "Quick add presets")

      SettingsPresetGrid(
        values: displayPresetValues,
        onTap: { value in
          editingPreset = PresetEditItem(value: value)
        },
        onAdd: {
          if values.count < Self.maxQuickAddButtons {
            isAddingPreset = true
          } else if let last = displayPresetValues.last {
            editingPreset = PresetEditItem(value: last)
          }
        }
      )
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

      SettingsDestructiveRow(label: "Delete counter") {
        showDeleteConfirmation = true
      }
      .padding(.bottom, SpaceToken.u3)
    }
  }

  private var navigationTitle: String {
    if includeNameField {
      return "Counter settings"
    }
    return title
  }

  private var trimmedName: String {
    nameText.trimmingCharacters(in: .whitespaces)
  }

  private var hasActiveGoal: Bool {
    parsedGoal != nil
  }

  private var displayPresetValues: [Int] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaultPresets)
  }

  private var canSave: Bool {
    if includeNameField, trimmedName.isEmpty {
      return false
    }
    let trimmedGoal = goalText.trimmingCharacters(in: .whitespaces)
    if !trimmedGoal.isEmpty, parsedGoal == nil {
      return false
    }
    return true
  }

  private var parsedGoal: Int? {
    guard let value = Int(goalText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }

  private func saveAndDismiss() {
    onSave(
      CounterSettingsSave(
        name: includeNameField ? trimmedName : nil,
        buttonValues: Array(values.sorted().prefix(Self.maxQuickAddButtons)),
        goal: parsedGoal,
        resetPeriod: resetPeriod,
        resetAnchorDay: resetPeriod == .daily ? 1 : resetAnchorDay,
        goalDirection: locksGoalDirection ? .countDown : goalDirection,
        paletteIndex: includeNameField ? paletteIndex : nil
      )
    )
    dismiss()
  }

  private func replacePreset(old: Int, with new: Int) {
    guard new > 0 else { return }

    if let index = values.firstIndex(of: old) {
      values[index] = new
    } else if values.count < Self.maxQuickAddButtons {
      values.append(new)
    }

    values = QuickAddConfiguration.normalizedPresets(values)
  }

  private func addPreset(_ value: Int) {
    guard value > 0, values.count < Self.maxQuickAddButtons, !values.contains(value) else { return }
    values.append(value)
    values = QuickAddConfiguration.normalizedPresets(values)
  }

  private func ordinalDay(_ day: Int) -> String {
    let suffix: String
    switch day % 10 {
    case 1 where day != 11: suffix = "st"
    case 2 where day != 12: suffix = "nd"
    case 3 where day != 13: suffix = "rd"
    default: suffix = "th"
    }
    return "\(day)\(suffix)"
  }
}

private struct PresetEditItem: Identifiable {
  let value: Int
  var id: Int { value }
}

// MARK: - Settings controls

private enum SettingsToken {
  static let sectionHeaderOpacity: CGFloat = 0.5
  static let sectionSpacing: CGFloat = SpaceToken.x5
}

private struct SettingsSectionDivider: View {
  var body: some View {
    SettingsDivider()
      .padding(.vertical, SettingsToken.sectionSpacing)
  }
}

private struct SettingsSectionHeader: View {
  @Environment(\.semanticColors) private var colors

  let title: String

  var body: some View {
    Text(title)
      .font(CounterTextStyle.settingsSectionHeader.font)
      .tracking(CounterTextStyle.settingsSectionHeader.tracking ?? 0)
      .foregroundStyle(colors.textPrimary.opacity(SettingsToken.sectionHeaderOpacity))
      .padding(.bottom, SpaceToken.u1)
  }
}

private struct SettingsLabeledField: View {
  @Environment(\.semanticColors) private var colors

  let label: String
  @Binding var text: String
  var keyboardType: UIKeyboardType = .default
  var placeholder: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.x1) {
      Text(label)
        .font(CounterTextStyle.settingsSectionHeader.font)
        .tracking(CounterTextStyle.settingsSectionHeader.tracking ?? 0)
        .foregroundStyle(colors.textPrimary.opacity(SettingsToken.sectionHeaderOpacity))

      TextField(placeholder, text: $text)
        .font(CounterTextStyle.settingsFieldValue.font)
        .tracking(CounterTextStyle.settingsFieldValue.tracking ?? 0)
        .foregroundStyle(colors.textPrimary)
        .keyboardType(keyboardType)
    }
    .padding(.vertical, SpaceToken.u2)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SettingsStaticRow: View {
  @Environment(\.semanticColors) private var colors

  let icon: CounterLucideIconName
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: SpaceToken.u2) {
      CounterLucideIcon(icon: icon, color: colors.textPrimary)

      Text(label)
        .counterTextStyle(.settingsRowLabel)

      Spacer(minLength: SpaceToken.u1)

      Text(value)
        .counterTextStyle(.settingsRowValue)
    }
    .padding(.vertical, SpaceToken.u2)
  }
}

private struct SettingsPickerRow<Option: Hashable>: View {
  @Environment(\.semanticColors) private var colors

  let icon: CounterLucideIconName
  let label: String
  @Binding var selection: Option
  let options: [(option: Option, title: String)]

  private var selectedTitle: String {
    options.first { $0.option == selection }?.title ?? ""
  }

  var body: some View {
    ZStack(alignment: .leading) {
      HStack(spacing: SpaceToken.u2) {
        CounterLucideIcon(icon: icon, color: colors.textPrimary)

        Text(label)
          .counterTextStyle(.settingsRowLabel, compact: true)

        Spacer(minLength: SpaceToken.u1)

        Text(selectedTitle)
          .counterTextStyle(.settingsRowValue, compact: true)

        CounterLucideIcon(icon: .chevronsUpDown, color: colors.textPrimary)
      }
      .padding(.vertical, SpaceToken.u2)
      .frame(maxWidth: .infinity, alignment: .leading)
      .allowsHitTesting(false)

      Menu {
        ForEach(options, id: \.option) { entry in
          Button(entry.title) {
            selection = entry.option
          }
        }
      } label: {
        Color.clear
          .frame(maxWidth: .infinity)
          .frame(minHeight: SizeToken.quickAddHeight)
          .contentShape(Rectangle())
      }
      .menuStyle(.borderlessButton)
    }
  }
}

private struct SettingsPresetButton: View {
  @Environment(\.semanticColors) private var colors

  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(label)
        .counterTextStyle(.settingsRowLabel, color: .primary)
        .frame(maxWidth: .infinity)
        .frame(height: SizeToken.quickAddHeight)
        .background(
          ComponentColor.listActionButtonFill(colors),
          in: RadiusToken.continuousButton
        )
    }
    .buttonStyle(.plain)
  }
}

private struct SettingsColorSwatchButton: View {
  @Environment(\.semanticColors) private var colors

  let fill: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: RadiusToken.sm, style: .continuous)
        .fill(fill)
        .overlay {
          RoundedRectangle(cornerRadius: RadiusToken.sm, style: .continuous)
            .inset(by: BorderToken.colourSwatch / 2)
            .stroke(
              isSelected
                ? ComponentColor.colourSwatchBorderSelected(colors)
                : ComponentColor.colourSwatchBorderDefault(colors),
              lineWidth: BorderToken.colourSwatch
            )
        }
        .frame(height: SizeToken.quickAddHeight)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct SettingsColorSwatchGrid: View {
  @Environment(\.colorScheme) private var colorScheme

  @Binding var selection: Int

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing),
      count: SizeToken.gridColumnCount
    )
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(CounterPaletteTokens.slotsSortedByColor) { slot in
        SettingsColorSwatchButton(
          fill: ComponentColor.colourSwatchFill(slot, colorScheme: colorScheme),
          isSelected: selection == slot.id
        ) {
          selection = slot.id
        }
      }
    }
  }
}

private struct SettingsPresetGrid: View {
  let values: [Int]
  let onTap: (Int) -> Void
  let onAdd: () -> Void

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing),
      count: SizeToken.gridColumnCount
    )
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(values, id: \.self) { value in
        SettingsPresetButton(label: "\(value)") {
          onTap(value)
        }
      }

      SettingsPresetButton(label: "…") {
        onAdd()
      }
    }
  }
}

#Preview {
  CounterSettingsView(title: "Protein Settings", values: [10, 20, 50], counter: CustomCounter(name: "Protein")) { _ in }
}
