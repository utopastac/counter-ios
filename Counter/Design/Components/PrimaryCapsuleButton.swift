import SwiftUI

enum CapsuleButtonKind {
  case primary
  case secondary
}

/// Full-width capsule action button. Primary = high-contrast fill; secondary = soft grey fill.
struct CapsuleButton: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  var kind: CapsuleButtonKind = .primary
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .counterTextStyle(.button, color: labelColorRole)
        .frame(maxWidth: .infinity)
        .frame(height: SizeToken.primaryButtonHeight)
        .background(fill, in: RadiusToken.continuousButton)
        .foregroundStyle(foreground)
    }
    .buttonStyle(.plain)
    .tint(foreground)
    .opacity(isEnabled ? 1 : OpacityToken.disabledButton)
    .disabled(!isEnabled)
  }

  private var fill: Color {
    switch kind {
    case .primary: colors.interactivePrimaryFill
    case .secondary: colors.interactiveSecondaryFill
    }
  }

  private var foreground: Color {
    switch kind {
    case .primary: colors.interactivePrimaryForeground
    case .secondary: colors.interactiveSecondaryForeground
    }
  }

  private var labelColorRole: CounterTextStyleModifier.TextColorRole {
    switch kind {
    case .primary: .onInteractiveFill
    case .secondary: .onInteractiveSecondaryFill
    }
  }
}

struct PrimaryCapsuleButton: View {
  let title: String
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    CapsuleButton(title: title, kind: .primary, isEnabled: isEnabled, action: action)
  }
}

struct SecondaryCapsuleButton: View {
  let title: String
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    CapsuleButton(title: title, kind: .secondary, isEnabled: isEnabled, action: action)
  }
}

#Preview {
  VStack(spacing: SpaceToken.u2) {
    PrimaryCapsuleButton(title: "Get started") {}
    SecondaryCapsuleButton(title: "Back") {}
    PrimaryCapsuleButton(title: "Save", isEnabled: false) {}
  }
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
