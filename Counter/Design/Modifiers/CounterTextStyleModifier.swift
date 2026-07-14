import SwiftUI

struct CounterTextStyleModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let style: CounterTextStyle
  var colorRole: TextColorRole = .primary

  enum TextColorRole {
    case primary
    case secondary
    case tertiary
    case emphasis
    case disabled
    case inverse
    case accent
    case onInteractiveFill
  }

  func body(content: Content) -> some View {
    content
      .font(style.font)
      .tracking(style.tracking ?? 0)
      .lineSpacing(style.lineSpacing)
      .frame(minHeight: style.lineHeight, alignment: .center)
      .foregroundStyle(foregroundColor)
  }

  private var foregroundColor: Color {
    switch colorRole {
    case .primary:
      return colors.textPrimary
    case .secondary:
      return colors.textSecondary
    case .tertiary:
      return colors.textTertiary
    case .emphasis:
      return colors.textEmphasis
    case .disabled:
      return colors.textDisabled
    case .inverse:
      return colors.textInverse
    case .accent:
      return colors.accentPrimary
    case .onInteractiveFill:
      return colors.interactivePrimaryForeground
    }
  }
}

extension View {
  func counterTextStyle(
    _ style: CounterTextStyle,
    color role: CounterTextStyleModifier.TextColorRole = .primary
  ) -> some View {
    modifier(CounterTextStyleModifier(style: style, colorRole: role))
  }
}
