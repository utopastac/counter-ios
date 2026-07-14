import SwiftUI

/// Tier 2 — semantic colors resolved per color scheme (and optional counter accent).
struct SemanticColors: Equatable {
  var textPrimary: Color
  var textSecondary: Color
  var textTertiary: Color
  var textEmphasis: Color
  var textDisabled: Color
  var textInverse: Color
  var textHistoryChartAxis: Color

  var surfaceBackdrop: Color
  var surfaceCounterBackground: Color
  var surfacePrimary: Color
  var surfaceGlassFill: Color
  var surfaceGlassFillSubtle: Color
  var surfaceGlassStroke: Color
  var surfaceGlassStrokeStrong: Color
  var surfaceTint: Color

  var borderSubtle: Color
  var borderStrong: Color
  var borderSettingsDivider: Color
  var borderColourSwatch: Color

  var accentPrimary: Color
  var accentOnAccent: Color

  var interactivePrimaryFill: Color
  var interactivePrimaryForeground: Color
  var interactiveDisabledFill: Color
  var interactiveDisabledForeground: Color

  var toggleTrack: Color
  var toggleThumb: Color

  var surfaceSheet: Color
  var surfaceKeypad: Color
  var surfaceKeypadKey: Color
  var surfaceHistoryMuted: Color

  var progressTrack: Color
  var progressFill: Color
  var progressOverGoal: Color

  var progressRingTrack: Color
  var progressRingFill: Color
  var progressRingOverfillOutline: Color

  var statusSuccess: Color
  var statusWarning: Color
  var statusDanger: Color
  var statusNeutral: Color
  var statusInfo: Color

  static let dark = SemanticColors(
    textPrimary: BaseColor.white,
    textSecondary: BaseColor.WhiteAlpha.a550,
    textTertiary: BaseColor.WhiteAlpha.a650,
    textEmphasis: BaseColor.WhiteAlpha.a950,
    textDisabled: BaseColor.WhiteAlpha.a450,
    textInverse: BaseColor.black,
    textHistoryChartAxis: BaseColor.WhiteAlpha.a500,
    surfaceBackdrop: BaseColor.Neutral.darkBackdrop,
    surfaceCounterBackground: BaseColor.Neutral.darkBackdrop,
    surfacePrimary: BaseColor.Neutral.darkBackdrop,
    surfaceGlassFill: BaseColor.WhiteAlpha.a140,
    surfaceGlassFillSubtle: BaseColor.WhiteAlpha.a100,
    surfaceGlassStroke: BaseColor.WhiteAlpha.a120,
    surfaceGlassStrokeStrong: BaseColor.WhiteAlpha.a180,
    surfaceTint: BaseColor.WhiteAlpha.a100,
    borderSubtle: BaseColor.WhiteAlpha.a100,
    borderStrong: BaseColor.WhiteAlpha.a180,
    borderSettingsDivider: BaseColor.WhiteAlpha.a180,
    borderColourSwatch: BaseColor.WhiteAlpha.a250,
    accentPrimary: BaseColor.Brand.blue500,
    accentOnAccent: BaseColor.white,
    interactivePrimaryFill: BaseColor.white,
    interactivePrimaryForeground: BaseColor.black,
    interactiveDisabledFill: BaseColor.WhiteAlpha.a250,
    interactiveDisabledForeground: BaseColor.WhiteAlpha.a450,
    toggleTrack: BaseColor.Neutral.toggleTrack,
    toggleThumb: BaseColor.white,
    surfaceSheet: BaseColor.Neutral.darkBackdrop,
    surfaceKeypad: BaseColor.WhiteAlpha.a100,
    surfaceKeypadKey: BaseColor.WhiteAlpha.a140,
    surfaceHistoryMuted: BaseColor.Neutral.darkMutedSurface,
    progressTrack: BaseColor.WhiteAlpha.a140,
    progressFill: BaseColor.Brand.blue500,
    progressOverGoal: BaseColor.Orange.orange500.opacity(0.95),
    progressRingTrack: BaseColor.WhiteAlpha.a100,
    progressRingFill: BaseColor.Yellow.yellow500,
    progressRingOverfillOutline: BaseColor.WhiteAlpha.a180,
    statusSuccess: BaseColor.Green.green500,
    statusWarning: BaseColor.Orange.orange500,
    statusDanger: BaseColor.Red.red500,
    statusNeutral: BaseColor.Mint.mint500,
    statusInfo: BaseColor.Brand.blue500
  )

  static let light = SemanticColors(
    textPrimary: BaseColor.black,
    textSecondary: BaseColor.BlackAlpha.a140,
    textTertiary: BaseColor.BlackAlpha.a180,
    textEmphasis: BaseColor.black,
    textDisabled: BaseColor.BlackAlpha.a100,
    textInverse: BaseColor.white,
    textHistoryChartAxis: BaseColor.BlackAlpha.a500,
    surfaceBackdrop: BaseColor.Neutral.lightBackdrop,
    surfaceCounterBackground: BaseColor.Neutral.lightBackdrop,
    surfacePrimary: BaseColor.white,
    surfaceGlassFill: BaseColor.BlackAlpha.a060,
    surfaceGlassFillSubtle: BaseColor.BlackAlpha.a040,
    surfaceGlassStroke: BaseColor.BlackAlpha.a100,
    surfaceGlassStrokeStrong: BaseColor.BlackAlpha.a140,
    surfaceTint: BaseColor.BlackAlpha.a040,
    borderSubtle: BaseColor.BlackAlpha.a080,
    borderStrong: BaseColor.BlackAlpha.a140,
    borderSettingsDivider: BaseColor.BlackAlpha.a140,
    borderColourSwatch: BaseColor.Neutral.keypadKey,
    accentPrimary: BaseColor.Brand.blue500,
    accentOnAccent: BaseColor.white,
    interactivePrimaryFill: BaseColor.black,
    interactivePrimaryForeground: BaseColor.white,
    interactiveDisabledFill: BaseColor.BlackAlpha.a060,
    interactiveDisabledForeground: BaseColor.BlackAlpha.a100,
    toggleTrack: BaseColor.Neutral.toggleTrack,
    toggleThumb: BaseColor.white,
    surfaceSheet: BaseColor.white,
    surfaceKeypad: BaseColor.white,
    surfaceKeypadKey: BaseColor.Neutral.keypadKey,
    surfaceHistoryMuted: BaseColor.Neutral.mutedSurface,
    progressTrack: BaseColor.BlackAlpha.a080,
    progressFill: BaseColor.Brand.blue500,
    progressOverGoal: BaseColor.Orange.orange500,
    progressRingTrack: BaseColor.BlackAlpha.a100,
    progressRingFill: BaseColor.Yellow.yellow500,
    progressRingOverfillOutline: BaseColor.BlackAlpha.a100,
    statusSuccess: BaseColor.Green.green500,
    statusWarning: BaseColor.Orange.orange500,
    statusDanger: BaseColor.Red.red500,
    statusNeutral: BaseColor.Mint.mint500,
    statusInfo: BaseColor.Brand.blue500
  )

  static func forColorScheme(_ scheme: ColorScheme) -> SemanticColors {
    scheme == .dark ? .dark : .light
  }

  func withAccent(_ accent: Color) -> SemanticColors {
    var copy = self
    copy.accentPrimary = accent
    copy.progressFill = accent
    return copy
  }

  func withCounterTheme(_ palette: CounterPaletteSlot, colorScheme: ColorScheme) -> SemanticColors {
    var copy = self
    let foreground = palette.foreground(for: colorScheme)
    let background = palette.background(for: colorScheme)

    copy.surfaceCounterBackground = background
    copy.surfaceBackdrop = background
    copy.textPrimary = foreground
    copy.textSecondary = foreground
    copy.textTertiary = foreground
    copy.textEmphasis = foreground
    copy.textDisabled = foreground.opacity(0.35)
    copy.textInverse = palette.buttonForeground(for: colorScheme)
    copy.textHistoryChartAxis = foreground.opacity(0.5)
    copy.borderSubtle = foreground.opacity(0.14)
    copy.borderStrong = foreground.opacity(0.22)
    copy.borderSettingsDivider = foreground.opacity(0.22)
    copy.borderColourSwatch = foreground.opacity(colorScheme == .dark ? 0.28 : 0.18)
    copy.interactivePrimaryFill = foreground
    copy.interactivePrimaryForeground = background
    copy.interactiveDisabledFill = foreground.opacity(0.18)
    copy.interactiveDisabledForeground = palette.buttonForeground(for: colorScheme).opacity(0.45)
    copy.progressRingFill = foreground
    copy.progressRingTrack = palette.subtleForeground(for: colorScheme)
    copy.progressRingOverfillOutline = foreground.opacity(colorScheme == .dark ? 0.45 : 0.28)
    copy.surfaceGlassFill = foreground.opacity(0.08)
    copy.surfaceGlassFillSubtle = foreground.opacity(0.05)
    copy.surfaceGlassStroke = foreground.opacity(0.12)
    copy.surfaceHistoryMuted = foreground.opacity(0.08)
    copy.accentPrimary = foreground
    return copy
  }
}

/// Tier 3 — component-level color aliases.
enum ComponentColor {
  static func glassButtonFill(_ colors: SemanticColors) -> Color {
    colors.surfaceGlassFill
  }

  static func glassButtonStroke(_ colors: SemanticColors) -> Color {
    colors.surfaceGlassStroke
  }

  static func listActionButtonFill(_ colors: SemanticColors) -> Color {
    colors.borderSubtle
  }

  static func settingsDividerFill(_ colors: SemanticColors) -> Color {
    colors.borderSettingsDivider
  }

  static func colourSwatchBorderDefault(_ colors: SemanticColors) -> Color {
    colors.borderColourSwatch
  }

  static func colourSwatchBorderSelected(_ colors: SemanticColors) -> Color {
    colors.textPrimary
  }

  static func colourSwatchFill(
    _ palette: CounterPaletteSlot,
    colorScheme: ColorScheme
  ) -> Color {
    palette.background(for: colorScheme)
  }

  static func pagerDotActive(_ colors: SemanticColors) -> Color {
    colors.textPrimary
  }

  static func pagerDotInactive(_ colors: SemanticColors) -> Color {
    colors.textDisabled
  }

  static func revealCardStroke(_ colors: SemanticColors, progress: CGFloat) -> Color {
    colors.borderSubtle.opacity(progress)
  }

  static func revealCardShadow(_ colors: SemanticColors, progress: CGFloat) -> Color {
    Color.black.opacity(0.15 * min(max(progress, 0), 1))
  }

  static func primaryButtonFill(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryFill : colors.interactiveDisabledFill
  }

  static func primaryButtonForeground(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryForeground : colors.interactiveDisabledForeground
  }

  static func sheetPrimaryButtonFill(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryFill : colors.interactiveDisabledFill
  }

  static func sheetPrimaryButtonForeground(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryForeground : colors.interactiveDisabledForeground
  }

  static func toggleTrackFill(_ colors: SemanticColors) -> Color {
    colors.toggleTrack
  }

  static func toggleThumbFill(_ colors: SemanticColors) -> Color {
    colors.toggleThumb
  }

  static func progressRingTrack(_ colors: SemanticColors) -> Color {
    colors.progressRingTrack
  }

  static func progressRingFill(_ colors: SemanticColors) -> Color {
    colors.progressRingFill
  }

  static func progressRingOverfillOutline(_ colors: SemanticColors) -> Color {
    colors.progressRingOverfillOutline
  }

  static func historyChartBackground(_ colors: SemanticColors) -> Color {
    colors.surfaceHistoryMuted
  }

  static func historyChartBarFill(_ colors: SemanticColors) -> Color {
    colors.textPrimary
  }

  static func historyChartGridLine(_ colors: SemanticColors) -> Color {
    colors.borderSubtle
  }

  static func historySegmentTrack(_ colors: SemanticColors) -> Color {
    colors.surfaceHistoryMuted
  }

  static func historySegmentActiveFill(_ colors: SemanticColors) -> Color {
    colors.interactivePrimaryFill
  }

  static func historyChartAxisLabel(_ colors: SemanticColors) -> Color {
    colors.textHistoryChartAxis
  }
}
