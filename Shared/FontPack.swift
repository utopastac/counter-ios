import SwiftUI

/// Global typeface pack for the app type ramp.
///
/// System packs use `Font.Design` (SF Pro / Rounded / New York / SF Mono).
/// Custom packs resolve built-in iOS faces by PostScript name (Avenir, Futura).
nonisolated enum FontPack: String, Codable, CaseIterable, Identifiable {
  case `default`
  case soft
  case editorial
  case technical
  case geometric
  case nineteenTwentySeven = "1927"

  var id: String { rawValue }

  var label: String {
    switch self {
    case .default: "Default"
    case .soft: "Soft"
    case .editorial: "Editorial"
    case .technical: "Technical"
    case .geometric: "Geometric"
    case .nineteenTwentySeven: "1927"
    }
  }

  /// Resolved SwiftUI font for a size/weight pair in this pack.
  func font(size: CGFloat, weight: Font.Weight) -> Font {
    switch self {
    case .default:
      return .system(size: size, weight: weight, design: .default)
    case .soft:
      return .system(size: size, weight: weight, design: .rounded)
    case .editorial:
      // New York — Apple's system serif. Editorial keeps a single regular weight
      // across the type ramp for a more bookish, even texture.
      return .system(size: size, weight: .regular, design: .serif)
    case .technical:
      return .system(size: size, weight: weight, design: .monospaced)
    case .geometric:
      return .custom(Self.avenirPostScriptName(for: weight), size: size)
    case .nineteenTwentySeven:
      // Futura Medium only — a single even weight across the type ramp.
      return .custom(Self.futuraMediumPostScriptName, size: size)
    }
  }

  /// PostScript name for Avenir at the closest available weight.
  static func avenirPostScriptName(for weight: Font.Weight) -> String {
    switch weight {
    case .ultraLight, .thin, .light:
      return "Avenir-Light"
    case .regular:
      return "Avenir-Roman"
    case .medium:
      return "Avenir-Medium"
    case .semibold, .bold:
      return "Avenir-Heavy"
    case .heavy, .black:
      return "Avenir-Black"
    default:
      return "Avenir-Roman"
    }
  }

  /// iOS ships Futura Medium as the primary non-condensed face.
  static let futuraMediumPostScriptName = "Futura-Medium"
}
