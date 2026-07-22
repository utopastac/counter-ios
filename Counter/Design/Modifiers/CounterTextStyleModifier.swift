import SwiftUI

struct CounterTextStyleModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors
  @Environment(\.designSystem) private var designSystem

  let style: CounterTextStyle
  var colorRole: TextColorRole = .primary
  var compact: Bool = false

  enum TextColorRole {
    case primary
    case secondary
    case tertiary
    case emphasis
    case disabled
    case inverse
    case accent
    case onInteractiveFill
    case onInteractiveSecondaryFill
    case historyChartAxis
    case danger
  }

  private var fontPack: FontPack {
    FontPack(rawValue: designSystem.fontPackRaw) ?? .default
  }

  private var resolvedFont: Font {
    style.definition.font(pack: fontPack)
  }

  func body(content: Content) -> some View {
    Group {
      if compact {
        content
          .font(resolvedFont)
          .tracking(style.tracking ?? 0)
          .foregroundStyle(foregroundColor)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        content
          .font(resolvedFont)
          .tracking(style.tracking ?? 0)
          .lineSpacing(style.lineSpacing)
          .frame(minHeight: style.lineHeight, alignment: .center)
          .foregroundStyle(foregroundColor)
      }
    }
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
    case .onInteractiveSecondaryFill:
      return colors.interactiveSecondaryForeground
    case .historyChartAxis:
      return ComponentColor.historyChartAxisLabel(colors)
    case .danger:
      return colors.statusDanger
    }
  }
}

extension View {
  func counterTextStyle(
    _ style: CounterTextStyle,
    color role: CounterTextStyleModifier.TextColorRole = .primary,
    compact: Bool = false
  ) -> some View {
    modifier(CounterTextStyleModifier(style: style, colorRole: role, compact: compact))
  }
}
