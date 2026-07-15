import SwiftUI

struct NumericKeypad: View {
  @Environment(\.semanticColors) private var colors

  @Binding var text: String

  var maxDigits: Int = 6

  private let columns = [
    GridItem(.flexible(), spacing: SheetToken.keypadKeySpacing),
    GridItem(.flexible(), spacing: SheetToken.keypadKeySpacing),
    GridItem(.flexible(), spacing: SheetToken.keypadKeySpacing)
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: SheetToken.keypadKeySpacing) {
      ForEach(1...9, id: \.self) { digit in
        KeypadKeyButton(title: "\(digit)") {
          append("\(digit)")
        }
      }

      Color.clear
        .frame(height: SheetToken.keypadKeyHeight)
        .accessibilityHidden(true)

      KeypadKeyButton(title: "0") {
        append("0")
      }

      KeypadKeyButton(icon: .deleteBackward) {
        deleteLast()
      }
      .accessibilityLabel("Delete")
    }
    .padding(.horizontal, SheetToken.horizontal)
    .padding(.top, SheetToken.keypadTopSpacing)
    .padding(.bottom, SheetToken.keypadBottom)
    .safeAreaPadding(.bottom, SpaceToken.u1)
  }

  private func append(_ digit: String) {
    text = AmountInput.appendingDigit(digit, to: text, maxDigits: maxDigits)
  }

  private func deleteLast() {
    guard !text.isEmpty else { return }
    text.removeLast()
  }
}

private struct KeypadKeyButton: View {
  @Environment(\.semanticColors) private var colors

  let title: String?
  let icon: CounterLucideIconName?
  let action: () -> Void

  init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.icon = nil
    self.action = action
  }

  init(icon: CounterLucideIconName, action: @escaping () -> Void) {
    self.title = nil
    self.icon = icon
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Group {
        if let icon {
          CounterLucideIcon(icon: icon, color: colors.textPrimary, size: SizeToken.iconGlyph)
        } else if let title {
          Text(title)
            .counterTextStyle(.sheetKeypadDigit)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: SheetToken.keypadKeyHeight)
      .background(
        colors.surfaceKeypadKey,
        in: RadiusToken.continuous(SheetToken.keypadKeyCornerRadius)
      )
      .foregroundStyle(colors.textPrimary)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  @Previewable @State var amount = "70"

  return AmountEntrySheet(
    title: "Add amount",
    headerIcon: .plus,
    actionTitle: "Add",
    initialText: amount,
    onSubmit: { _ in }
  )
  .environment(\.counterAccent, nil)
  .counterDesignSystemFromColorScheme()
}
