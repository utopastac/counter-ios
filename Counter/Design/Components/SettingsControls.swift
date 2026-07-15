import SwiftUI

// MARK: - Settings controls
//
// Reusable rows/fields/grids for counter settings sheets (create + edit).
// Extracted from the settings view so they can be shared and reasoned about
// independently of the sheet's own state and save/delete logic.

enum SettingsToken {
  static let sectionHeaderOpacity: CGFloat = 0.5
  static let sectionSpacing: CGFloat = SpaceToken.x5
}

struct SettingsSectionDivider: View {
  var body: some View {
    SettingsDivider()
      .padding(.vertical, SettingsToken.sectionSpacing)
  }
}

struct SettingsSectionHeader: View {
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

struct SettingsLabeledField: View {
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
    .padding(.vertical, SpaceToken.u2)
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

struct SettingsEditablePresetField: View {
  @Environment(\.semanticColors) private var colors

  let value: Int
  let onCommit: (Int) -> Void

  @State private var text: String
  @FocusState private var isFocused: Bool

  init(value: Int, onCommit: @escaping (Int) -> Void) {
    self.value = value
    self.onCommit = onCommit
    _text = State(initialValue: String(value))
  }

  var body: some View {
    TextField("", text: $text)
      .counterTextStyle(.settingsRowLabel, color: .primary)
      .textFieldStyle(.plain)
      .multilineTextAlignment(.center)
      .keyboardType(.numberPad)
      .focused($isFocused)
      .frame(maxWidth: .infinity)
      .frame(height: SizeToken.quickAddHeight)
      .background(
        ComponentColor.listActionButtonFill(colors),
        in: RadiusToken.continuousButton
      )
      .onChange(of: text) { _, newValue in
        let sanitized = AmountInput.sanitizedDigits(newValue, maxLength: 6)
        if sanitized != newValue {
          text = sanitized
        }
      }
      .onChange(of: value) { _, newValue in
        guard !isFocused else { return }
        text = String(newValue)
      }
      .onChange(of: isFocused) { _, focused in
        if !focused {
          commit()
        }
      }
  }

  private func commit() {
    guard let parsed = AmountInput.parsePositiveInt(text) else {
      text = String(value)
      return
    }

    guard parsed != value else { return }
    onCommit(parsed)
  }
}

struct SettingsPresetGrid: View {
  @Binding var values: [Int]
  let defaults: [Int]

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing),
      count: SizeToken.gridColumnCount
    )
  }

  private var displayValues: [Int] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaults)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(Array(displayValues.enumerated()), id: \.offset) { _, presetValue in
        SettingsEditablePresetField(value: presetValue) { newValue in
          commitPreset(replacing: presetValue, with: newValue)
        }
      }
    }
  }

  private func commitPreset(replacing old: Int, with new: Int) {
    values = QuickAddConfiguration.replacingPreset(old, with: new, in: values)
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
