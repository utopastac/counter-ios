import SwiftUI

/// Typography tokens — semantic text styles mapped to SwiftUI fonts.
enum CounterTextStyle: CaseIterable {
  case heroTitle
  case heroValue
  case sectionLabel
  case bodySecondary
  case bodyTertiary
  case numericLarge
  case numericCompact
  case numericRing
  case headline
  case subheadlineSemibold
  case caption
  case caption2
  case iconButton
  case sheetTitle
  case sheetSubtitle
  case sheetAmount
  case sheetKeypadDigit

  var font: Font {
    switch self {
    case .heroTitle:
      return .system(size: 30, weight: .thin, design: .rounded)
    case .heroValue:
      return .system(size: 72, weight: .ultraLight, design: .rounded)
    case .sectionLabel:
      return .caption.weight(.semibold)
    case .bodySecondary:
      return .subheadline
    case .bodyTertiary:
      return .subheadline
    case .numericLarge:
      return .title3.weight(.semibold).monospacedDigit()
    case .numericCompact:
      return .subheadline.weight(.semibold).monospacedDigit()
    case .numericRing:
      return .system(size: 14, weight: .semibold, design: .rounded).monospacedDigit()
    case .headline:
      return .headline
    case .subheadlineSemibold:
      return .subheadline.weight(.semibold).monospacedDigit()
    case .caption:
      return .caption
    case .caption2:
      return .caption2
    case .iconButton:
      return .body.weight(.semibold)
    case .sheetTitle:
      return .title2.weight(.bold)
    case .sheetSubtitle:
      return .subheadline
    case .sheetAmount:
      return .system(size: 56, weight: .bold, design: .rounded).monospacedDigit()
    case .sheetKeypadDigit:
      return .title.weight(.regular).monospacedDigit()
    }
  }

  var tracking: CGFloat? {
    switch self {
    case .sectionLabel:
      return 1.1
    default:
      return nil
    }
  }

  func ringFontSize(for ringSize: CGFloat) -> Font {
    .system(size: ringSize * 0.22, weight: .semibold, design: .rounded).monospacedDigit()
  }
}

enum TypographyToken {
  static let heroTitle = CounterTextStyle.heroTitle.font
  static let heroValue = CounterTextStyle.heroValue.font
  static let sectionLabel = CounterTextStyle.sectionLabel.font
  static let numericLarge = CounterTextStyle.numericLarge.font
  static let numericCompact = CounterTextStyle.numericCompact.font
}
