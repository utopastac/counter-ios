import SwiftUI

struct PrimaryCapsuleButton: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .counterTextStyle(.button, color: .onInteractiveFill)
        .frame(maxWidth: .infinity)
        .frame(height: SizeToken.primaryButtonHeight)
        .background(
          colors.interactivePrimaryFill,
          in: RadiusToken.continuousButton
        )
        .foregroundStyle(colors.interactivePrimaryForeground)
    }
    .buttonStyle(.plain)
    .tint(colors.interactivePrimaryForeground)
    .opacity(isEnabled ? 1 : OpacityToken.disabledButton)
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
