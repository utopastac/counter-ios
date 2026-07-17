import SwiftUI

struct LargeAmountInput: View {
  @Environment(\.semanticColors) private var colors

  let text: String
  let prefix: String?

  init(text: String, prefix: String? = nil) {
    self.text = text
    self.prefix = prefix
  }

  private var trimmed: String {
    text.trimmingCharacters(in: .whitespaces)
  }

  private var isPlaceholder: Bool {
    trimmed.isEmpty
  }

  private var hasDecimal: Bool {
    trimmed.contains(".")
  }

  private var integerPart: String {
    guard hasDecimal else {
      return trimmed.isEmpty ? "0" : trimmed
    }
    let before = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
      .first
      .map(String.init) ?? "0"
    return before.isEmpty ? "0" : before
  }

  private var enteredDecimalDigits: String {
    guard let separatorIndex = trimmed.firstIndex(of: ".") else { return "" }
    return String(trimmed[trimmed.index(after: separatorIndex)...])
  }

  private var accessibilityDisplay: String {
    if isPlaceholder { return "0" }
    if hasDecimal {
      let padded = enteredDecimalDigits.padding(toLength: 2, withPad: "0", startingAt: 0)
      return "\(integerPart).\(padded)"
    }
    return trimmed
  }

  private var amountForeground: Color {
    isPlaceholder ? colors.textDisabled : colors.textPrimary
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: SpaceToken.x1) {
      if let prefix {
        Text(prefix)
          .font(CounterTextStyle.mainNumber.font)
          .tracking(CounterTextStyle.mainNumber.tracking ?? 0)
          .foregroundStyle(amountForeground)
      }

      Text(amountAttributedText)
        .font(CounterTextStyle.mainNumber.font)
        .tracking(CounterTextStyle.mainNumber.tracking ?? 0)
        .minimumScaleFactor(0.45)
        .lineLimit(1)
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.15), value: accessibilityDisplay)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityLabel("Amount")
    .accessibilityValue(accessibilityDisplay)
  }

  private var amountAttributedText: AttributedString {
    if isPlaceholder {
      return attributed("0", color: colors.textDisabled)
    }

    guard hasDecimal else {
      return attributed(trimmed, color: colors.textPrimary)
    }

    // Always show two decimal places; unfilled trailing zeros stay in the placeholder colour.
    var result = attributed(integerPart, color: colors.textPrimary)
    result += attributed(".", color: colors.textPrimary)

    let entered = Array(enteredDecimalDigits)
    for index in 0..<2 {
      if index < entered.count {
        result += attributed(String(entered[index]), color: colors.textPrimary)
      } else {
        result += attributed("0", color: colors.textDisabled)
      }
    }
    return result
  }

  private func attributed(_ string: String, color: Color) -> AttributedString {
    var value = AttributedString(string)
    value.foregroundColor = color
    return value
  }
}

#Preview {
  VStack(spacing: SpaceToken.x4) {
    LargeAmountInput(text: "100", prefix: "$")
    LargeAmountInput(text: "12.")
    LargeAmountInput(text: "12.5")
    LargeAmountInput(text: "12.50")
    LargeAmountInput(text: "")
  }
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
