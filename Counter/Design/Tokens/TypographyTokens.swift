import SwiftUI

// MARK: - Tier 1: Primitives

/// Font size ramp — never use directly in views; reference via `TypeStyle` or semantic tokens.
enum FontSizeToken {
  static let xs: CGFloat = 12
  static let sm: CGFloat = 14
  static let md: CGFloat = 16
  static let lg: CGFloat = 18
  static let xxl: CGFloat = 24
  static let xxxl: CGFloat = 40
  static let x5xl: CGFloat = 80
}

/// Font weight ramp.
enum FontWeightToken {
  static let regular: Font.Weight = .regular
  static let medium: Font.Weight = .medium
  static let semibold: Font.Weight = .semibold
  static let bold: Font.Weight = .bold
}

/// Letter-spacing presets expressed as a percentage of font size (negative = tighter).
enum FontTrackingToken {
  static let tight2: CGFloat = -2
  static let tight3: CGFloat = -3
  static let tight5: CGFloat = -5

  static func value(size: CGFloat, percent: CGFloat) -> CGFloat {
    size * (percent / 100)
  }
}

// MARK: - Tier 2: Type ramp (size + weight + metrics)

struct TypeStyleDefinition: Equatable {
  let size: CGFloat
  let weight: Font.Weight
  let lineHeight: CGFloat
  let trackingPercent: CGFloat?
  let monospacedDigits: Bool

  var font: Font {
    let base = Font.system(size: size, weight: weight, design: .default)
    return monospacedDigits ? base.monospacedDigit() : base
  }

  var tracking: CGFloat? {
    guard let trackingPercent else { return nil }
    return FontTrackingToken.value(size: size, percent: trackingPercent)
  }

  var lineSpacing: CGFloat {
    max(lineHeight - size, 0)
  }
}

/// Composed type ramp entries — size/weight pairings with line height and tracking.
enum TypeStyle {
  static let x5xlSemibold = TypeStyleDefinition(
    size: FontSizeToken.x5xl,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.x5xl,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let xxxlSemibold = TypeStyleDefinition(
    size: FontSizeToken.xxxl,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.xxxl,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let xxlMedium = TypeStyleDefinition(
    size: FontSizeToken.xxl,
    weight: FontWeightToken.medium,
    lineHeight: FontSizeToken.xxl,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let xxlSemibold = TypeStyleDefinition(
    size: FontSizeToken.xxl,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.xxl,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let lgSemibold = TypeStyleDefinition(
    size: FontSizeToken.lg,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.lg,
    trackingPercent: FontTrackingToken.tight3,
    monospacedDigits: false
  )

  static let lgSemiboldMono = TypeStyleDefinition(
    size: FontSizeToken.lg,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.lg,
    trackingPercent: FontTrackingToken.tight3,
    monospacedDigits: true
  )

  static let lgRegular = TypeStyleDefinition(
    size: FontSizeToken.lg,
    weight: FontWeightToken.regular,
    lineHeight: FontSizeToken.lg,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let mdMedium = TypeStyleDefinition(
    size: FontSizeToken.md,
    weight: FontWeightToken.medium,
    lineHeight: FontSizeToken.md,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let mdSemibold = TypeStyleDefinition(
    size: FontSizeToken.md,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.md,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let mdRegular = TypeStyleDefinition(
    size: FontSizeToken.md,
    weight: FontWeightToken.regular,
    lineHeight: FontSizeToken.md,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let mdSemiboldMono = TypeStyleDefinition(
    size: FontSizeToken.md,
    weight: FontWeightToken.semibold,
    lineHeight: FontSizeToken.md,
    trackingPercent: FontTrackingToken.tight5,
    monospacedDigits: true
  )

  static let smRegular = TypeStyleDefinition(
    size: FontSizeToken.sm,
    weight: FontWeightToken.regular,
    lineHeight: FontSizeToken.sm,
    trackingPercent: FontTrackingToken.tight2,
    monospacedDigits: false
  )

  static let xsRegular = TypeStyleDefinition(
    size: FontSizeToken.xs,
    weight: FontWeightToken.regular,
    lineHeight: FontSizeToken.xs,
    trackingPercent: nil,
    monospacedDigits: false
  )

}

// MARK: - Tier 3: Semantic use-case tokens

/// Semantic text styles for product UI — each maps to a `TypeStyle` ramp entry.
enum CounterTextStyle: CaseIterable {
  case mainNumber
  case heroSubtitle
  case listCardNumber
  case listCardNumberCompact
  case listCardTitle
  case listCardCaption
  case pageTitle
  case sectionTitle
  case rowHeavy
  case rowLight
  case button
  case meta

  // History screen
  case historyListDate
  case historyListValue
  case historyChartAxis
  case historySegment

  // Legacy aliases — mapped to the new ramp.
  case heroValue
  case bodySecondary
  case numericLarge
  case caption
  case sheetTitle
  case sheetSubtitle
  case sheetKeypadDigit
  case settingsSectionHeader
  case settingsFieldValue
  case settingsRowLabel
  case settingsRowValue

  var definition: TypeStyleDefinition {
    switch self {
    case .mainNumber, .heroValue:
      return TypeStyle.x5xlSemibold
    case .heroSubtitle:
      return TypeStyle.xxlSemibold
    case .listCardNumber:
      return TypeStyle.xxxlSemibold
    case .listCardNumberCompact:
      return TypeStyle.xxlSemibold
    case .listCardTitle:
      return TypeStyle.lgSemibold
    case .listCardCaption:
      return TypeStyle.smRegular
    case .pageTitle, .sheetTitle:
      return TypeStyle.xxlMedium
    case .sectionTitle:
      return TypeStyle.lgSemibold
    case .rowHeavy, .numericLarge:
      return TypeStyle.lgSemiboldMono
    case .rowLight, .bodySecondary, .sheetSubtitle:
      return TypeStyle.lgRegular
    case .button:
      return TypeStyle.mdSemiboldMono
    case .meta, .caption:
      return TypeStyle.smRegular
    case .historyListDate:
      return TypeStyle.lgRegular
    case .historyListValue:
      return TypeStyle.xxlSemibold
    case .historyChartAxis:
      return TypeStyle.xsRegular
    case .historySegment:
      return TypeStyle.mdMedium
    case .sheetKeypadDigit:
      return TypeStyle.xxlSemibold
    case .settingsSectionHeader:
      return TypeStyle.lgSemibold
    case .settingsFieldValue:
      return TypeStyle.xxxlSemibold
    case .settingsRowLabel:
      return TypeStyle.mdSemibold
    case .settingsRowValue:
      return TypeStyle.mdRegular
    }
  }

  var font: Font { definition.font }
  var tracking: CGFloat? { definition.tracking }
  var lineHeight: CGFloat? { definition.lineHeight }
  var fontSize: CGFloat? { definition.size }
  var lineSpacing: CGFloat { definition.lineSpacing }
}
