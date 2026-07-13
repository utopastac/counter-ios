import SwiftUI

/// Tier 2 — semantic colors resolved per color scheme (and optional counter accent).
struct SemanticColors: Equatable {
  var textPrimary: Color
  var textSecondary: Color
  var textTertiary: Color
  var textEmphasis: Color
  var textDisabled: Color
  var textInverse: Color

  var surfaceBackdrop: Color
  var surfacePrimary: Color
  var surfaceGlassFill: Color
  var surfaceGlassFillSubtle: Color
  var surfaceGlassStroke: Color
  var surfaceGlassStrokeStrong: Color
  var surfaceTint: Color

  var borderSubtle: Color
  var borderStrong: Color

  var accentPrimary: Color
  var accentOnAccent: Color

  var interactivePrimaryFill: Color
  var interactivePrimaryForeground: Color
  var interactiveDisabledFill: Color
  var interactiveDisabledForeground: Color

  var surfaceSheet: Color
  var surfaceKeypad: Color
  var surfaceKeypadKey: Color

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
    surfaceBackdrop: BaseColor.Neutral.darkBackdrop,
    surfacePrimary: BaseColor.WhiteAlpha.a100,
    surfaceGlassFill: BaseColor.WhiteAlpha.a140,
    surfaceGlassFillSubtle: BaseColor.WhiteAlpha.a100,
    surfaceGlassStroke: BaseColor.WhiteAlpha.a120,
    surfaceGlassStrokeStrong: BaseColor.WhiteAlpha.a180,
    surfaceTint: BaseColor.WhiteAlpha.a100,
    borderSubtle: BaseColor.WhiteAlpha.a100,
    borderStrong: BaseColor.WhiteAlpha.a180,
    accentPrimary: BaseColor.Brand.blue500,
    accentOnAccent: BaseColor.white,
    interactivePrimaryFill: BaseColor.white,
    interactivePrimaryForeground: BaseColor.black,
    interactiveDisabledFill: BaseColor.WhiteAlpha.a250,
    interactiveDisabledForeground: BaseColor.WhiteAlpha.a450,
    surfaceSheet: BaseColor.Neutral.darkBackdrop,
    surfaceKeypad: BaseColor.WhiteAlpha.a100,
    surfaceKeypadKey: BaseColor.WhiteAlpha.a140,
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
    surfaceBackdrop: BaseColor.Neutral.lightBackdrop,
    surfacePrimary: BaseColor.white,
    surfaceGlassFill: BaseColor.BlackAlpha.a060,
    surfaceGlassFillSubtle: BaseColor.BlackAlpha.a040,
    surfaceGlassStroke: BaseColor.BlackAlpha.a100,
    surfaceGlassStrokeStrong: BaseColor.BlackAlpha.a140,
    surfaceTint: BaseColor.BlackAlpha.a040,
    borderSubtle: BaseColor.BlackAlpha.a080,
    borderStrong: BaseColor.BlackAlpha.a140,
    accentPrimary: BaseColor.Brand.blue500,
    accentOnAccent: BaseColor.white,
    interactivePrimaryFill: BaseColor.black,
    interactivePrimaryForeground: BaseColor.white,
    interactiveDisabledFill: BaseColor.BlackAlpha.a060,
    interactiveDisabledForeground: BaseColor.BlackAlpha.a100,
    surfaceSheet: BaseColor.white,
    surfaceKeypad: Color(red: 0.82, green: 0.83, blue: 0.85),
    surfaceKeypadKey: BaseColor.white,
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
}

/// Tier 3 — component-level color aliases.
enum ComponentColor {
  static func glassButtonFill(_ colors: SemanticColors) -> Color {
    colors.surfaceGlassFill
  }

  static func glassButtonStroke(_ colors: SemanticColors) -> Color {
    colors.surfaceGlassStroke
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
    BaseColor.BlackAlpha.a280.opacity(progress)
  }

  static func primaryButtonFill(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryFill : colors.interactiveDisabledFill
  }

  static func primaryButtonForeground(_ colors: SemanticColors, isEnabled: Bool) -> Color {
    isEnabled ? colors.interactivePrimaryForeground : colors.interactiveDisabledForeground
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
}
