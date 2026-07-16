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

  var surfacePrimary: Color

  var borderSubtle: Color
  var borderSettingsDivider: Color
  var borderColourSwatch: Color

  var accentPrimary: Color

  var interactivePrimaryFill: Color
  var interactivePrimaryForeground: Color
  var interactiveDisabledFill: Color
  var interactiveDisabledForeground: Color

  /// Toggle track fill while off.
  var toggleTrackOff: Color
  /// Toggle track fill while on.
  var toggleTrackOn: Color
  /// Toggle thumb fill while off.
  var toggleThumbOff: Color
  /// Toggle thumb fill while on.
  var toggleThumbOn: Color

  var surfaceSheet: Color
  var surfaceKeypadKey: Color
  var surfaceHistoryMuted: Color

  var progressRingTrack: Color
  var progressRingFill: Color
  var progressRingOverfillOutline: Color

  var statusDanger: Color

  static let dark = SemanticColors(
    textPrimary: BaseColor.white,
    textSecondary: BaseColor.WhiteAlpha.a550,
    textTertiary: BaseColor.WhiteAlpha.a650,
    textEmphasis: BaseColor.WhiteAlpha.a950,
    textDisabled: BaseColor.WhiteAlpha.a450,
    textInverse: BaseColor.black,
    textHistoryChartAxis: BaseColor.WhiteAlpha.a500,
    surfacePrimary: BaseColor.Neutral.darkBackdrop,
    borderSubtle: BaseColor.WhiteAlpha.a100,
    borderSettingsDivider: BaseColor.WhiteAlpha.a250,
    borderColourSwatch: BaseColor.WhiteAlpha.a250,
    accentPrimary: BaseColor.Brand.blue500,
    interactivePrimaryFill: BaseColor.white,
    interactivePrimaryForeground: BaseColor.black,
    interactiveDisabledFill: BaseColor.WhiteAlpha.a250,
    interactiveDisabledForeground: BaseColor.WhiteAlpha.a450,
    toggleTrackOff: BaseColor.Neutral.toggleTrackOffDark,
    toggleTrackOn: BaseColor.white,
    toggleThumbOff: BaseColor.white,
    toggleThumbOn: BaseColor.black,
    surfaceSheet: BaseColor.Neutral.darkBackdrop,
    surfaceKeypadKey: BaseColor.WhiteAlpha.a140,
    surfaceHistoryMuted: BaseColor.Neutral.darkMutedSurface,
    progressRingTrack: BaseColor.WhiteAlpha.a100,
    progressRingFill: BaseColor.Yellow.yellow500,
    progressRingOverfillOutline: BaseColor.Neutral.darkBackdrop,
    statusDanger: BaseColor.Red.red500
  )

  static let light = SemanticColors(
    textPrimary: BaseColor.black,
    textSecondary: BaseColor.BlackAlpha.a140,
    textTertiary: BaseColor.BlackAlpha.a180,
    textEmphasis: BaseColor.black,
    textDisabled: BaseColor.BlackAlpha.a100,
    textInverse: BaseColor.white,
    textHistoryChartAxis: BaseColor.BlackAlpha.a500,
    surfacePrimary: BaseColor.white,
    borderSubtle: BaseColor.BlackAlpha.a080,
    borderSettingsDivider: BaseColor.black,
    borderColourSwatch: BaseColor.Neutral.keypadKey,
    accentPrimary: BaseColor.Brand.blue500,
    interactivePrimaryFill: BaseColor.black,
    interactivePrimaryForeground: BaseColor.white,
    interactiveDisabledFill: BaseColor.BlackAlpha.a060,
    interactiveDisabledForeground: BaseColor.BlackAlpha.a100,
    toggleTrackOff: BaseColor.Neutral.toggleTrackOffLight,
    toggleTrackOn: BaseColor.black,
    toggleThumbOff: BaseColor.white,
    toggleThumbOn: BaseColor.white,
    surfaceSheet: BaseColor.white,
    surfaceKeypadKey: BaseColor.Neutral.keypadKey,
    surfaceHistoryMuted: BaseColor.Neutral.mutedSurface,
    progressRingTrack: BaseColor.BlackAlpha.a100,
    progressRingFill: BaseColor.Yellow.yellow500,
    progressRingOverfillOutline: BaseColor.Neutral.lightBackdrop,
    statusDanger: BaseColor.Red.red500
  )

  static func forColorScheme(_ scheme: ColorScheme) -> SemanticColors {
    scheme == .dark ? .dark : .light
  }

  func withAccent(_ accent: Color) -> SemanticColors {
    var copy = self
    copy.accentPrimary = accent
    return copy
  }

  func withCounterTheme(_ palette: CounterPaletteSlot, colorScheme: ColorScheme) -> SemanticColors {
    var copy = self
    let foreground = palette.foreground(for: colorScheme)
    let background = palette.background(for: colorScheme)

    copy.textPrimary = foreground
    copy.textSecondary = foreground
    copy.textTertiary = foreground
    copy.textEmphasis = foreground
    copy.textDisabled = foreground.opacity(0.35)
    copy.textInverse = palette.buttonForeground(for: colorScheme)
    copy.textHistoryChartAxis = foreground.opacity(0.5)
    copy.borderSubtle = foreground.opacity(0.14)
    copy.borderSettingsDivider = foreground.opacity(0.22)
    copy.borderColourSwatch = foreground.opacity(colorScheme == .dark ? 0.28 : 0.18)
    copy.interactivePrimaryFill = foreground
    copy.interactivePrimaryForeground = background
    copy.interactiveDisabledFill = foreground.opacity(0.18)
    copy.interactiveDisabledForeground = palette.buttonForeground(for: colorScheme).opacity(0.45)
    copy.progressRingFill = foreground
    copy.progressRingTrack = palette.subtleForeground(for: colorScheme)
    // The counter's own card background (not `foreground`-based): the outline reads as a
    // "cut-out" gap back down to the card behind the ring, so it stays visible against the
    // fill color instead of blending into a translucent version of the same hue.
    copy.progressRingOverfillOutline = background
    copy.surfaceHistoryMuted = foreground.opacity(0.08)
    copy.accentPrimary = foreground
    return copy
  }
}

/// Tier 3 — component-level color aliases.
enum ComponentColor {
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

  static func revealCardStroke(_ colors: SemanticColors, progress: CGFloat) -> Color {
    colors.borderSubtle.opacity(progress)
  }

  static func sheetPrimaryButtonFill(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryFill : colors.interactiveDisabledFill
  }

  static func sheetPrimaryButtonForeground(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryForeground : colors.interactiveDisabledForeground
  }

  static func toggleTrackFill(_ colors: SemanticColors, isOn: Bool) -> Color {
    isOn ? colors.toggleTrackOn : colors.toggleTrackOff
  }

  static func toggleThumbFill(_ colors: SemanticColors, isOn: Bool) -> Color {
    isOn ? colors.toggleThumbOn : colors.toggleThumbOff
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
