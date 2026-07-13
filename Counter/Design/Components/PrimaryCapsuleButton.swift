import SwiftUI

struct PrimaryCapsuleButton: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(CounterTextStyle.headline.font)
        .frame(maxWidth: .infinity)
        .frame(height: SizeToken.primaryButtonHeight)
        .background(
          ComponentColor.primaryButtonFill(colors, isEnabled: isEnabled),
          in: Capsule()
        )
        .foregroundStyle(ComponentColor.primaryButtonForeground(colors, isEnabled: isEnabled))
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }
}

#Preview {
  VStack(spacing: SpaceToken.x3) {
    PrimaryCapsuleButton(title: "Add", isEnabled: true) {}
    PrimaryCapsuleButton(title: "Save", isEnabled: false) {}
  }
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
