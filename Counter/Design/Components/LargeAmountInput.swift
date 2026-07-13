import SwiftUI

struct LargeAmountInput: View {
  @Environment(\.semanticColors) private var colors

  let text: String
  let prefix: String?

  init(text: String, prefix: String? = nil) {
    self.text = text
    self.prefix = prefix
  }

  private var displayText: String {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    if trimmed.isEmpty {
      return "0"
    }
    return trimmed
  }

  private var isPlaceholder: Bool {
    text.trimmingCharacters(in: .whitespaces).isEmpty
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: SpaceToken.x1) {
      if let prefix {
        Text(prefix)
          .counterTextStyle(.sheetAmount, color: isPlaceholder ? .disabled : .primary)
      }

      Text(displayText)
        .counterTextStyle(.sheetAmount, color: isPlaceholder ? .disabled : .primary)
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.15), value: displayText)
    }
    .frame(maxWidth: .infinity)
    .accessibilityLabel("Amount")
    .accessibilityValue(displayText)
  }
}

#Preview {
  VStack(spacing: SpaceToken.x4) {
    LargeAmountInput(text: "100", prefix: "$")
    LargeAmountInput(text: "")
  }
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
