import SwiftUI

// MARK: - Settings controls
//
// Reusable rows/fields/grids for counter settings sheets (create + edit).
// Extracted from the settings view so they can be shared and reasoned about
// independently of the sheet's own state and save/delete logic.

enum SettingsToken {
  /// Equal space above and below each section divider.
  static let sectionSpacing: CGFloat = SpaceToken.u2
  /// Gap between settings sections when using space instead of a divider.
  static let sectionGap: CGFloat = SpaceToken.u5
  /// Space from a section header/label to its content.
  static let headerToContent: CGFloat = SpaceToken.u1
  /// Space from a field label to its text field.
  static let labelToField: CGFloat = SpaceToken.x1
  /// Vertical gap between stacked labeled fields (Title / Unit, etc.).
  static let fieldSpacing: CGFloat = SpaceToken.u3
}

struct SettingsSectionDivider: View {
  var body: some View {
    SettingsDivider()
      .padding(.vertical, SettingsToken.sectionSpacing)
  }
}

extension View {
  /// Gives number-pad settings fields (which have no return key) a way to dismiss the keyboard
  /// without committing the whole sheet: an accessory "Done" button plus swipe-to-dismiss.
  /// Apply to the sheet's `ScrollView`.
  func settingsKeyboardDismissible() -> some View {
    scrollDismissesKeyboard(.interactively)
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer(minLength: 0)
          Button("Done") { CounterKeyboard.resign() }
        }
      }
  }
}

struct SettingsSectionHeader: View {
  @Environment(\.semanticColors) private var colors

  let title: String

  var body: some View {
    Text(title)
      .font(CounterTextStyle.settingsSectionHeader.font)
      .tracking(CounterTextStyle.settingsSectionHeader.tracking ?? 0)
      .foregroundStyle(colors.textPrimary)
      .padding(.bottom, SettingsToken.headerToContent)
  }
}

struct SettingsLabeledField: View {
  @Environment(\.semanticColors) private var colors

  let label: String
  @Binding var text: String
  var keyboardType: UIKeyboardType = .default
  var placeholder: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: SettingsToken.labelToField) {
      Text(label)
        .font(CounterTextStyle.settingsSectionHeader.font)
        .tracking(CounterTextStyle.settingsSectionHeader.tracking ?? 0)
        .foregroundStyle(colors.textPrimary)

      TextField(placeholder, text: $text)
        .font(CounterTextStyle.settingsFieldValue.font)
        .tracking(CounterTextStyle.settingsFieldValue.tracking ?? 0)
        .foregroundStyle(colors.textPrimary)
        .textFieldStyle(.plain)
        .keyboardType(keyboardType)
        .padding(.horizontal, SpaceToken.u2)
        .padding(.vertical, SpaceToken.u1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          ComponentColor.settingsFieldFill(colors),
          in: RadiusToken.continuousButton
        )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct SettingsStaticRow: View {
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
    .frame(minHeight: SizeToken.quickAddHeight)
  }
}

struct SettingsActionRow: View {
  @Environment(\.semanticColors) private var colors

  let icon: CounterLucideIconName
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: SpaceToken.u2) {
        CounterLucideIcon(icon: icon, color: colors.textPrimary)

        Text(label)
          .counterTextStyle(.settingsRowLabel)

        Spacer(minLength: SpaceToken.u1)
      }
      .frame(minHeight: SizeToken.quickAddHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct SettingsPickerRow<Option: Hashable>: View {
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
      .frame(minHeight: SizeToken.quickAddHeight)
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

struct SettingsEditablePresetField: View {
  @Environment(\.semanticColors) private var colors

  let value: Double
  let onCommit: (Double) -> Void

  @State private var text: String
  @FocusState private var isFocused: Bool

  init(value: Double, onCommit: @escaping (Double) -> Void) {
    self.value = value
    self.onCommit = onCommit
    _text = State(initialValue: CounterFormatting.editingText(for: value))
  }

  var body: some View {
    TextField("", text: $text)
      .counterTextStyle(.settingsRowLabel, color: .primary)
      .textFieldStyle(.plain)
      .multilineTextAlignment(.center)
      .keyboardType(.decimalPad)
      .focused($isFocused)
      .frame(maxWidth: .infinity)
      .frame(height: SizeToken.quickAddHeight)
      .background(
        ComponentColor.listActionButtonFill(colors),
        in: RadiusToken.continuousButton
      )
      .onChange(of: text) { _, newValue in
        let sanitized = AmountInput.sanitizedSignedDecimal(newValue, maxLength: 8)
        if sanitized != newValue {
          text = sanitized
          return
        }
        // Commit as-you-type so Done can save without an explicit blur (number pads have
        // no return key, and sheet dismiss used to race the focus-loss commit).
        if let parsed = AmountInput.parsePositiveAmount(sanitized), parsed != value {
          onCommit(parsed)
        }
      }
      .onChange(of: value) { _, newValue in
        guard !isFocused else { return }
        text = CounterFormatting.editingText(for: newValue)
      }
      .onChange(of: isFocused) { _, focused in
        if !focused {
          commit()
        }
      }
  }

  private func commit() {
    guard let parsed = AmountInput.parsePositiveAmount(text) else {
      text = CounterFormatting.editingText(for: value)
      return
    }

    guard parsed != value else { return }
    onCommit(parsed)
  }
}

struct SettingsPresetGrid: View {
  @Binding var values: [Double]
  let defaults: [Double]

  /// Stable slot order while editing. Re-sorting `values` on every commit used to reshuffle
  /// the grid under the focused field (and fight the sheet's dismiss gesture).
  @State private var slots: [Double] = []

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing),
      count: SizeToken.gridColumnCount
    )
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(Array(slots.enumerated()), id: \.offset) { index, presetValue in
        SettingsEditablePresetField(value: presetValue) { newValue in
          commitPreset(at: index, to: newValue)
        }
      }
    }
    .onAppear {
      if slots.isEmpty {
        slots = QuickAddConfiguration.filledPresets(from: values, defaults: defaults)
      }
    }
  }

  private func commitPreset(at index: Int, to newValue: Double) {
    guard newValue > 0, slots.indices.contains(index) else { return }
    slots[index] = newValue
    // Persist the full visible set (including previously default-filled slots) without
    // reassigning `slots`, so the focused field doesn't jump when values are normalized.
    values = QuickAddConfiguration.normalizedPresets(slots)
  }
}

struct SettingsColorSwatchButton: View {
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

struct SettingsColorSwatchGrid: View {
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue

  @Binding var selection: Int

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing),
      count: SizeToken.gridColumnCount
    )
  }

  private var slots: [CounterPaletteSlot] {
    let _ = colorPackRaw
    return CounterPaletteTokens.slotsSortedByColor
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(slots) { slot in
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
