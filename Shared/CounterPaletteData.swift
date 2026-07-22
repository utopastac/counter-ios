import Foundation
import SwiftUI

/// RGB triple in 0…1, shared by solid slots and gradient stops.
typealias CounterPaletteRGB = (red: Double, green: Double, blue: Double)

/// Whether a colour pack follows the app dark-mode toggle or locks to one scheme.
enum CounterColorPackAppearanceLock: Equatable {
  case adaptive
  case alwaysDark
  case alwaysLight

  func resolvedScheme(for appScheme: ColorScheme) -> ColorScheme {
    switch self {
    case .adaptive: return appScheme
    case .alwaysDark: return .dark
    case .alwaysLight: return .light
    }
  }
}

/// Raw colour values for a single palette slot within a colour pack.
///
/// `lightRGB` / `darkRGB` are always present as the solid representative (pager lerp,
/// ring darken, glass tint). Optional gradient stop lists turn the visible fill into a
/// `LinearGradient` when they contain at least two colours.
struct CounterPaletteColorData {
  let name: String
  let lightRGB: CounterPaletteRGB
  let darkRGB: CounterPaletteRGB
  let lightGradient: [CounterPaletteRGB]?
  let darkGradient: [CounterPaletteRGB]?

  init(
    name: String,
    lightRGB: CounterPaletteRGB,
    darkRGB: CounterPaletteRGB,
    lightGradient: [CounterPaletteRGB]? = nil,
    darkGradient: [CounterPaletteRGB]? = nil
  ) {
    self.name = name
    self.lightRGB = lightRGB
    self.darkRGB = darkRGB
    self.lightGradient = lightGradient
    self.darkGradient = darkGradient
  }

  var hasGradient: Bool {
    (lightGradient?.count ?? 0) >= 2 || (darkGradient?.count ?? 0) >= 2
  }

  func solidColor(for scheme: ColorScheme) -> Color {
    Self.color(scheme == .dark ? darkRGB : lightRGB)
  }

  /// Fill style for large surfaces — gradient when defined, otherwise solid.
  func backgroundStyle(
    for scheme: ColorScheme,
    startPoint: UnitPoint = .topLeading,
    endPoint: UnitPoint = .bottomTrailing
  ) -> AnyShapeStyle {
    if let gradient = linearGradient(for: scheme, startPoint: startPoint, endPoint: endPoint) {
      return AnyShapeStyle(gradient)
    }
    return AnyShapeStyle(solidColor(for: scheme))
  }

  func linearGradient(
    for scheme: ColorScheme,
    startPoint: UnitPoint = .topLeading,
    endPoint: UnitPoint = .bottomTrailing
  ) -> LinearGradient? {
    guard let stops = gradientStops(for: scheme), stops.count >= 2 else { return nil }
    return LinearGradient(
      colors: stops.map(Self.color),
      startPoint: startPoint,
      endPoint: endPoint
    )
  }

  private func gradientStops(for scheme: ColorScheme) -> [CounterPaletteRGB]? {
    if scheme == .dark {
      return darkGradient ?? lightGradient
    }
    return lightGradient ?? darkGradient
  }

  private static func color(_ rgb: CounterPaletteRGB) -> Color {
    Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
  }
}

/// Named packs of 10 counter colours. The active pack is chosen in global settings
/// and shared with widgets / watch via the App Group.
enum CounterColorPack: String, CaseIterable, Hashable, Identifiable {
  case muted
  case neon
  case metallic
  case pastel
  case clouds
  case ocean
  case forest
  case ember
  case desert
  case berry
  case gradient
  case aurora
  case dusk
  case nebula
  case twilight
  case bloom
  case dawn
  case water
  case sheen

  var id: String { rawValue }

  var label: String {
    switch self {
    case .muted: return "Muted"
    case .neon: return "Neon"
    case .metallic: return "Metallic"
    case .pastel: return "Pastel"
    case .clouds: return "Clouds"
    case .ocean: return "Ocean"
    case .forest: return "Forest"
    case .ember: return "Ember"
    case .desert: return "Desert"
    case .berry: return "Berry"
    case .gradient: return "Gradient"
    case .aurora: return "Aurora"
    case .dusk: return "Dusk"
    case .nebula: return "Nebula"
    case .twilight: return "Twilight"
    case .bloom: return "Bloom"
    case .dawn: return "Dawn"
    case .water: return "Water"
    case .sheen: return "Sheen"
    }
  }

  /// Whether counter surfaces ignore the app dark-mode toggle for this pack.
  var appearanceLock: CounterColorPackAppearanceLock {
    switch self {
    case .aurora, .dusk, .nebula, .twilight:
      return .alwaysDark
    case .bloom, .dawn, .water:
      return .alwaysLight
    default:
      return .adaptive
    }
  }

  /// When true, counter surfaces always use this pack's dark fills and light
  /// foregrounds, ignoring the app dark-mode toggle.
  var forcesDarkAppearance: Bool {
    appearanceLock == .alwaysDark
  }

  /// When true, counter surfaces always use this pack's light fills and dark
  /// foregrounds, ignoring the app dark-mode toggle.
  var forcesLightAppearance: Bool {
    appearanceLock == .alwaysLight
  }

  /// Scheme used when reading this pack's slot colours / gradients.
  func resolvedScheme(for appScheme: ColorScheme) -> ColorScheme {
    appearanceLock.resolvedScheme(for: appScheme)
  }

  var entries: [CounterPaletteColorData] {
    switch self {
    case .muted: return Self.mutedEntries
    case .neon: return Self.neonEntries
    case .metallic: return Self.metallicEntries
    case .pastel: return Self.pastelEntries
    case .clouds: return Self.cloudsEntries
    case .ocean: return Self.oceanEntries
    case .forest: return Self.forestEntries
    case .ember: return Self.emberEntries
    case .desert: return Self.desertEntries
    case .berry: return Self.berryEntries
    case .gradient: return Self.gradientEntries
    case .aurora: return Self.auroraEntries
    case .dusk: return Self.duskEntries
    case .nebula: return Self.nebulaEntries
    case .twilight: return Self.twilightEntries
    case .bloom: return Self.bloomEntries
    case .dawn: return Self.dawnEntries
    case .water: return Self.waterEntries
    case .sheen: return Self.sheenEntries
    }
  }

  // MARK: - Muted (original)

  /// Calm, desaturated colours. Consecutive indices alternate cool / warm / green / neutral.
  private static let mutedEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Periwinkle",
      lightRGB: (0.79, 0.81, 0.88),
      darkRGB: (0.16, 0.17, 0.24)
    ),
    CounterPaletteColorData(
      name: "Sand",
      lightRGB: (0.91, 0.87, 0.81),
      darkRGB: (0.24, 0.21, 0.17)
    ),
    CounterPaletteColorData(
      name: "Lime",
      lightRGB: (0.84, 0.88, 0.66),
      darkRGB: (0.20, 0.22, 0.12)
    ),
    CounterPaletteColorData(
      name: "Mist",
      lightRGB: (0.96, 0.96, 0.97),
      darkRGB: (0.22, 0.22, 0.24)
    ),
    CounterPaletteColorData(
      name: "Blush",
      lightRGB: (0.90, 0.83, 0.84),
      darkRGB: (0.26, 0.16, 0.18)
    ),
    CounterPaletteColorData(
      name: "Sage",
      lightRGB: (0.78, 0.84, 0.80),
      darkRGB: (0.14, 0.22, 0.18)
    ),
    CounterPaletteColorData(
      name: "Sky",
      lightRGB: (0.76, 0.84, 0.89),
      darkRGB: (0.12, 0.20, 0.26)
    ),
    CounterPaletteColorData(
      name: "Clay",
      lightRGB: (0.88, 0.77, 0.70),
      darkRGB: (0.28, 0.18, 0.14)
    ),
    CounterPaletteColorData(
      name: "Slate",
      lightRGB: (0.75, 0.78, 0.83),
      darkRGB: (0.18, 0.19, 0.23)
    ),
    CounterPaletteColorData(
      name: "Butter",
      lightRGB: (0.92, 0.89, 0.72),
      darkRGB: (0.24, 0.22, 0.12)
    )
  ]

  // MARK: - Neon

  private static let neonEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Hot Pink",
      lightRGB: (1.00, 0.55, 0.78),
      darkRGB: (0.42, 0.06, 0.24)
    ),
    CounterPaletteColorData(
      name: "Electric Cyan",
      lightRGB: (0.45, 0.96, 0.98),
      darkRGB: (0.04, 0.30, 0.34)
    ),
    CounterPaletteColorData(
      name: "Acid Lime",
      lightRGB: (0.78, 1.00, 0.35),
      darkRGB: (0.18, 0.34, 0.04)
    ),
    CounterPaletteColorData(
      name: "Plasma",
      lightRGB: (0.72, 0.55, 1.00),
      darkRGB: (0.26, 0.08, 0.42)
    ),
    CounterPaletteColorData(
      name: "Laser Orange",
      lightRGB: (1.00, 0.68, 0.28),
      darkRGB: (0.40, 0.18, 0.04)
    ),
    CounterPaletteColorData(
      name: "Volt Green",
      lightRGB: (0.40, 1.00, 0.62),
      darkRGB: (0.04, 0.34, 0.16)
    ),
    CounterPaletteColorData(
      name: "Ultraviolet",
      lightRGB: (0.62, 0.42, 1.00),
      darkRGB: (0.20, 0.06, 0.40)
    ),
    CounterPaletteColorData(
      name: "Shock Yellow",
      lightRGB: (1.00, 0.96, 0.30),
      darkRGB: (0.34, 0.30, 0.04)
    ),
    CounterPaletteColorData(
      name: "Neon Blue",
      lightRGB: (0.42, 0.70, 1.00),
      darkRGB: (0.06, 0.16, 0.42)
    ),
    CounterPaletteColorData(
      name: "Signal Red",
      lightRGB: (1.00, 0.42, 0.48),
      darkRGB: (0.42, 0.06, 0.10)
    )
  ]

  // MARK: - Metallic

  private static let metallicEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Silver",
      lightRGB: (0.88, 0.89, 0.91),
      darkRGB: (0.28, 0.29, 0.32)
    ),
    CounterPaletteColorData(
      name: "Gold",
      lightRGB: (0.92, 0.84, 0.58),
      darkRGB: (0.34, 0.26, 0.10)
    ),
    CounterPaletteColorData(
      name: "Copper",
      lightRGB: (0.90, 0.68, 0.52),
      darkRGB: (0.34, 0.16, 0.10)
    ),
    CounterPaletteColorData(
      name: "Bronze",
      lightRGB: (0.84, 0.72, 0.52),
      darkRGB: (0.30, 0.20, 0.10)
    ),
    CounterPaletteColorData(
      name: "Rose Gold",
      lightRGB: (0.92, 0.76, 0.76),
      darkRGB: (0.34, 0.18, 0.20)
    ),
    CounterPaletteColorData(
      name: "Gunmetal",
      lightRGB: (0.76, 0.78, 0.82),
      darkRGB: (0.16, 0.18, 0.22)
    ),
    CounterPaletteColorData(
      name: "Platinum",
      lightRGB: (0.90, 0.90, 0.93),
      darkRGB: (0.24, 0.24, 0.28)
    ),
    CounterPaletteColorData(
      name: "Champagne",
      lightRGB: (0.94, 0.88, 0.76),
      darkRGB: (0.30, 0.24, 0.14)
    ),
    CounterPaletteColorData(
      name: "Steel",
      lightRGB: (0.70, 0.76, 0.84),
      darkRGB: (0.12, 0.16, 0.24)
    ),
    CounterPaletteColorData(
      name: "Pewter",
      lightRGB: (0.82, 0.80, 0.76),
      darkRGB: (0.22, 0.20, 0.18)
    )
  ]

  // MARK: - Pastel

  private static let pastelEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Cotton Candy",
      lightRGB: (0.98, 0.84, 0.90),
      darkRGB: (0.30, 0.16, 0.22)
    ),
    CounterPaletteColorData(
      name: "Lavender",
      lightRGB: (0.88, 0.84, 0.98),
      darkRGB: (0.22, 0.16, 0.32)
    ),
    CounterPaletteColorData(
      name: "Mint Cream",
      lightRGB: (0.82, 0.96, 0.88),
      darkRGB: (0.12, 0.28, 0.20)
    ),
    CounterPaletteColorData(
      name: "Peach",
      lightRGB: (0.98, 0.88, 0.80),
      darkRGB: (0.32, 0.20, 0.14)
    ),
    CounterPaletteColorData(
      name: "Baby Blue",
      lightRGB: (0.80, 0.90, 0.98),
      darkRGB: (0.12, 0.20, 0.32)
    ),
    CounterPaletteColorData(
      name: "Buttercream",
      lightRGB: (0.98, 0.95, 0.84),
      darkRGB: (0.30, 0.26, 0.12)
    ),
    CounterPaletteColorData(
      name: "Lilac",
      lightRGB: (0.92, 0.84, 0.96),
      darkRGB: (0.26, 0.16, 0.30)
    ),
    CounterPaletteColorData(
      name: "Coral Soft",
      lightRGB: (0.98, 0.80, 0.78),
      darkRGB: (0.32, 0.14, 0.14)
    ),
    CounterPaletteColorData(
      name: "Aqua Mist",
      lightRGB: (0.78, 0.94, 0.94),
      darkRGB: (0.10, 0.26, 0.28)
    ),
    CounterPaletteColorData(
      name: "Lemon Ice",
      lightRGB: (0.96, 0.96, 0.78),
      darkRGB: (0.28, 0.28, 0.12)
    )
  ]

  // MARK: - Clouds

  private static let cloudsEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Cumulus",
      lightRGB: (0.97, 0.97, 0.98),
      darkRGB: (0.20, 0.21, 0.24)
    ),
    CounterPaletteColorData(
      name: "Stratus",
      lightRGB: (0.90, 0.91, 0.93),
      darkRGB: (0.22, 0.23, 0.26)
    ),
    CounterPaletteColorData(
      name: "Dawn",
      lightRGB: (0.96, 0.90, 0.88),
      darkRGB: (0.28, 0.18, 0.18)
    ),
    CounterPaletteColorData(
      name: "Twilight",
      lightRGB: (0.88, 0.86, 0.94),
      darkRGB: (0.18, 0.16, 0.28)
    ),
    CounterPaletteColorData(
      name: "Overcast",
      lightRGB: (0.86, 0.88, 0.90),
      darkRGB: (0.20, 0.22, 0.24)
    ),
    CounterPaletteColorData(
      name: "Horizon",
      lightRGB: (0.84, 0.90, 0.96),
      darkRGB: (0.12, 0.18, 0.28)
    ),
    CounterPaletteColorData(
      name: "Fog",
      lightRGB: (0.93, 0.93, 0.92),
      darkRGB: (0.24, 0.24, 0.23)
    ),
    CounterPaletteColorData(
      name: "Sunset",
      lightRGB: (0.95, 0.86, 0.82),
      darkRGB: (0.30, 0.16, 0.14)
    ),
    CounterPaletteColorData(
      name: "Storm",
      lightRGB: (0.78, 0.82, 0.88),
      darkRGB: (0.14, 0.16, 0.22)
    ),
    CounterPaletteColorData(
      name: "Silver Lining",
      lightRGB: (0.92, 0.93, 0.95),
      darkRGB: (0.22, 0.23, 0.26)
    )
  ]

  // MARK: - Ocean

  private static let oceanEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Tide",
      lightRGB: (0.72, 0.86, 0.92),
      darkRGB: (0.08, 0.18, 0.26)
    ),
    CounterPaletteColorData(
      name: "Lagoon",
      lightRGB: (0.62, 0.88, 0.86),
      darkRGB: (0.06, 0.24, 0.24)
    ),
    CounterPaletteColorData(
      name: "Seafoam",
      lightRGB: (0.78, 0.92, 0.86),
      darkRGB: (0.10, 0.26, 0.20)
    ),
    CounterPaletteColorData(
      name: "Coral Reef",
      lightRGB: (0.94, 0.78, 0.76),
      darkRGB: (0.32, 0.14, 0.16)
    ),
    CounterPaletteColorData(
      name: "Abyss",
      lightRGB: (0.68, 0.76, 0.88),
      darkRGB: (0.08, 0.12, 0.28)
    ),
    CounterPaletteColorData(
      name: "Kelp",
      lightRGB: (0.74, 0.84, 0.70),
      darkRGB: (0.14, 0.24, 0.12)
    ),
    CounterPaletteColorData(
      name: "Pearl",
      lightRGB: (0.90, 0.92, 0.94),
      darkRGB: (0.20, 0.22, 0.26)
    ),
    CounterPaletteColorData(
      name: "Driftwood",
      lightRGB: (0.86, 0.80, 0.72),
      darkRGB: (0.26, 0.20, 0.14)
    ),
    CounterPaletteColorData(
      name: "Harbor",
      lightRGB: (0.70, 0.82, 0.90),
      darkRGB: (0.10, 0.18, 0.28)
    ),
    CounterPaletteColorData(
      name: "Anemone",
      lightRGB: (0.88, 0.74, 0.90),
      darkRGB: (0.26, 0.12, 0.28)
    )
  ]

  // MARK: - Forest

  private static let forestEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Moss",
      lightRGB: (0.78, 0.86, 0.68),
      darkRGB: (0.14, 0.24, 0.10)
    ),
    CounterPaletteColorData(
      name: "Fern",
      lightRGB: (0.70, 0.84, 0.72),
      darkRGB: (0.10, 0.26, 0.14)
    ),
    CounterPaletteColorData(
      name: "Pine",
      lightRGB: (0.68, 0.80, 0.72),
      darkRGB: (0.10, 0.20, 0.14)
    ),
    CounterPaletteColorData(
      name: "Canopy",
      lightRGB: (0.82, 0.90, 0.74),
      darkRGB: (0.16, 0.26, 0.10)
    ),
    CounterPaletteColorData(
      name: "Bark",
      lightRGB: (0.84, 0.76, 0.68),
      darkRGB: (0.26, 0.18, 0.12)
    ),
    CounterPaletteColorData(
      name: "Lichen",
      lightRGB: (0.86, 0.90, 0.78),
      darkRGB: (0.20, 0.26, 0.14)
    ),
    CounterPaletteColorData(
      name: "Thicket",
      lightRGB: (0.72, 0.78, 0.66),
      darkRGB: (0.14, 0.20, 0.10)
    ),
    CounterPaletteColorData(
      name: "Mushroom",
      lightRGB: (0.88, 0.82, 0.76),
      darkRGB: (0.28, 0.20, 0.16)
    ),
    CounterPaletteColorData(
      name: "Ivy",
      lightRGB: (0.74, 0.86, 0.78),
      darkRGB: (0.10, 0.24, 0.16)
    ),
    CounterPaletteColorData(
      name: "Soil",
      lightRGB: (0.82, 0.74, 0.64),
      darkRGB: (0.24, 0.16, 0.10)
    )
  ]

  // MARK: - Ember

  private static let emberEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Flame",
      lightRGB: (0.96, 0.72, 0.52),
      darkRGB: (0.36, 0.14, 0.06)
    ),
    CounterPaletteColorData(
      name: "Amber",
      lightRGB: (0.94, 0.80, 0.48),
      darkRGB: (0.34, 0.22, 0.06)
    ),
    CounterPaletteColorData(
      name: "Rust",
      lightRGB: (0.90, 0.68, 0.54),
      darkRGB: (0.32, 0.14, 0.08)
    ),
    CounterPaletteColorData(
      name: "Coal",
      lightRGB: (0.78, 0.76, 0.74),
      darkRGB: (0.16, 0.14, 0.14)
    ),
    CounterPaletteColorData(
      name: "Cinder",
      lightRGB: (0.92, 0.78, 0.70),
      darkRGB: (0.30, 0.16, 0.12)
    ),
    CounterPaletteColorData(
      name: "Glow",
      lightRGB: (0.96, 0.86, 0.62),
      darkRGB: (0.34, 0.24, 0.08)
    ),
    CounterPaletteColorData(
      name: "Smoke",
      lightRGB: (0.84, 0.82, 0.80),
      darkRGB: (0.20, 0.18, 0.18)
    ),
    CounterPaletteColorData(
      name: "Crimson Ash",
      lightRGB: (0.92, 0.66, 0.64),
      darkRGB: (0.34, 0.10, 0.10)
    ),
    CounterPaletteColorData(
      name: "Hearth",
      lightRGB: (0.90, 0.74, 0.58),
      darkRGB: (0.28, 0.16, 0.08)
    ),
    CounterPaletteColorData(
      name: "Sparks",
      lightRGB: (0.96, 0.88, 0.72),
      darkRGB: (0.32, 0.22, 0.10)
    )
  ]

  // MARK: - Desert

  /// Warm sand, terracotta, and cactus tones.
  private static let desertEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Dune",
      lightRGB: (0.94, 0.88, 0.76),
      darkRGB: (0.30, 0.24, 0.12)
    ),
    CounterPaletteColorData(
      name: "Adobe",
      lightRGB: (0.90, 0.74, 0.62),
      darkRGB: (0.32, 0.16, 0.10)
    ),
    CounterPaletteColorData(
      name: "Cactus",
      lightRGB: (0.78, 0.86, 0.72),
      darkRGB: (0.14, 0.24, 0.12)
    ),
    CounterPaletteColorData(
      name: "Ochre",
      lightRGB: (0.92, 0.80, 0.54),
      darkRGB: (0.34, 0.22, 0.08)
    ),
    CounterPaletteColorData(
      name: "Canyon",
      lightRGB: (0.88, 0.68, 0.58),
      darkRGB: (0.30, 0.12, 0.10)
    ),
    CounterPaletteColorData(
      name: "Mirage",
      lightRGB: (0.82, 0.88, 0.90),
      darkRGB: (0.12, 0.20, 0.24)
    ),
    CounterPaletteColorData(
      name: "Sienna",
      lightRGB: (0.86, 0.72, 0.58),
      darkRGB: (0.28, 0.16, 0.10)
    ),
    CounterPaletteColorData(
      name: "Agave",
      lightRGB: (0.74, 0.84, 0.78),
      darkRGB: (0.10, 0.22, 0.18)
    ),
    CounterPaletteColorData(
      name: "Sandstone",
      lightRGB: (0.91, 0.84, 0.74),
      darkRGB: (0.26, 0.20, 0.14)
    ),
    CounterPaletteColorData(
      name: "Clay Pot",
      lightRGB: (0.84, 0.70, 0.64),
      darkRGB: (0.28, 0.14, 0.12)
    )
  ]

  // MARK: - Berry

  /// Soft plum, raspberry, and grape tones.
  private static let berryEntries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Raspberry",
      lightRGB: (0.94, 0.72, 0.78),
      darkRGB: (0.34, 0.10, 0.16)
    ),
    CounterPaletteColorData(
      name: "Plum",
      lightRGB: (0.84, 0.74, 0.86),
      darkRGB: (0.24, 0.12, 0.28)
    ),
    CounterPaletteColorData(
      name: "Mulberry",
      lightRGB: (0.86, 0.70, 0.82),
      darkRGB: (0.28, 0.10, 0.24)
    ),
    CounterPaletteColorData(
      name: "Cream",
      lightRGB: (0.96, 0.92, 0.88),
      darkRGB: (0.26, 0.22, 0.18)
    ),
    CounterPaletteColorData(
      name: "Currant",
      lightRGB: (0.90, 0.68, 0.70),
      darkRGB: (0.32, 0.10, 0.14)
    ),
    CounterPaletteColorData(
      name: "Grape",
      lightRGB: (0.78, 0.74, 0.90),
      darkRGB: (0.16, 0.12, 0.30)
    ),
    CounterPaletteColorData(
      name: "Rosehip",
      lightRGB: (0.94, 0.80, 0.82),
      darkRGB: (0.32, 0.14, 0.16)
    ),
    CounterPaletteColorData(
      name: "Brambles",
      lightRGB: (0.80, 0.78, 0.86),
      darkRGB: (0.18, 0.16, 0.26)
    ),
    CounterPaletteColorData(
      name: "Boysenberry",
      lightRGB: (0.88, 0.72, 0.86),
      darkRGB: (0.26, 0.10, 0.26)
    ),
    CounterPaletteColorData(
      name: "Jam",
      lightRGB: (0.92, 0.76, 0.74),
      darkRGB: (0.30, 0.12, 0.12)
    )
  ]

  // MARK: - Gradient

  /// Adjacent spectrum pairs as real linear gradients (rose→coral, coral→amber, …).
  /// Adaptive: light and dark variants follow the app dark-mode toggle.
  private static let gradientEntries: [CounterPaletteColorData] = {
    let names = [
      "Rose", "Coral", "Amber", "Chartreuse", "Mint",
      "Aqua", "Sky", "Indigo", "Violet", "Fuchsia",
    ]
    let light: [CounterPaletteRGB] = [
      (0.96, 0.78, 0.82),
      (0.96, 0.76, 0.68),
      (0.96, 0.86, 0.62),
      (0.86, 0.94, 0.64),
      (0.70, 0.92, 0.80),
      (0.68, 0.90, 0.92),
      (0.70, 0.84, 0.96),
      (0.76, 0.78, 0.96),
      (0.88, 0.76, 0.96),
      (0.94, 0.74, 0.90),
    ]
    let dark: [CounterPaletteRGB] = [
      (0.34, 0.10, 0.16),
      (0.36, 0.14, 0.10),
      (0.34, 0.24, 0.08),
      (0.20, 0.28, 0.08),
      (0.08, 0.28, 0.18),
      (0.06, 0.26, 0.28),
      (0.08, 0.16, 0.32),
      (0.14, 0.12, 0.34),
      (0.26, 0.10, 0.32),
      (0.32, 0.08, 0.28),
    ]

    return names.indices.map { index in
      let next = (index + 1) % names.count
      let lightStart = light[index]
      let lightEnd = light[next]
      let lightMid = blendRGB(lightStart, lightEnd, t: 0.5)
      let darkStart = dark[index]
      let darkEnd = dark[next]
      let darkMid = blendRGB(darkStart, darkEnd, t: 0.5)
      return CounterPaletteColorData(
        name: names[index],
        lightRGB: lightMid,
        darkRGB: darkMid,
        lightGradient: [lightStart, lightMid, lightEnd],
        darkGradient: [darkStart, darkMid, darkEnd]
      )
    }
  }()

  // MARK: - Aurora (always dark)

  /// Cool northern-lights washes — emerald, teal, and violet on deep night fills.
  private static let auroraEntries: [CounterPaletteColorData] = alwaysDarkGradientEntries(
    names: [
      "Borealis", "Ion", "Curtain", "Pulse", "Veil",
      "Glacier", "Ribbon", "Corona", "Arc", "Noctilucent",
    ],
    tints: [
      (0.62, 1.00, 0.78),
      (0.45, 0.98, 0.92),
      (0.72, 0.88, 1.00),
      (0.78, 0.70, 1.00),
      (0.55, 1.00, 0.88),
      (0.70, 0.96, 1.00),
      (0.58, 0.92, 0.72),
      (0.82, 0.74, 1.00),
      (0.48, 0.90, 0.98),
      (0.88, 0.82, 1.00),
    ],
    fills: [
      (0.04, 0.18, 0.14),
      (0.04, 0.16, 0.20),
      (0.06, 0.10, 0.24),
      (0.12, 0.06, 0.26),
      (0.04, 0.20, 0.16),
      (0.05, 0.14, 0.22),
      (0.06, 0.16, 0.10),
      (0.14, 0.06, 0.22),
      (0.04, 0.12, 0.22),
      (0.10, 0.06, 0.20),
    ]
  )

  // MARK: - Dusk (always dark)

  /// Warm sunset into night — ember, rose, and indigo.
  private static let duskEntries: [CounterPaletteColorData] = alwaysDarkGradientEntries(
    names: [
      "Afterglow", "Emberline", "Horizon", "Marina", "Cinder",
      "Twilight", "Saffron", "Magenta Hour", "Indigo Fall", "Nightcap",
    ],
    tints: [
      (1.00, 0.78, 0.52),
      (1.00, 0.62, 0.48),
      (1.00, 0.72, 0.70),
      (0.92, 0.70, 1.00),
      (1.00, 0.84, 0.55),
      (0.78, 0.72, 1.00),
      (1.00, 0.88, 0.58),
      (1.00, 0.60, 0.78),
      (0.70, 0.76, 1.00),
      (1.00, 0.70, 0.62),
    ],
    fills: [
      (0.28, 0.10, 0.06),
      (0.30, 0.08, 0.10),
      (0.26, 0.08, 0.16),
      (0.14, 0.06, 0.24),
      (0.28, 0.12, 0.06),
      (0.10, 0.08, 0.24),
      (0.30, 0.16, 0.06),
      (0.28, 0.06, 0.16),
      (0.08, 0.08, 0.22),
      (0.18, 0.06, 0.10),
    ]
  )

  // MARK: - Nebula (always dark)

  /// Deep-space blooms — near-black bases with magenta, cobalt, and violet blooms.
  private static let nebulaEntries: [CounterPaletteColorData] = alwaysDarkGradientEntries(
    names: [
      "Void", "Quark", "Pulsar", "Nova", "Eclipse",
      "Cosmos", "Orion", "Singularity", "Photon", "Event Horizon",
    ],
    tints: [
      (0.85, 0.70, 1.00),
      (0.55, 0.78, 1.00),
      (1.00, 0.55, 0.85),
      (0.70, 0.92, 1.00),
      (0.92, 0.62, 1.00),
      (0.62, 0.70, 1.00),
      (1.00, 0.68, 0.78),
      (0.72, 0.58, 1.00),
      (0.58, 0.95, 1.00),
      (1.00, 0.58, 0.72),
    ],
    fills: [
      (0.05, 0.04, 0.12),
      (0.04, 0.06, 0.16),
      (0.14, 0.04, 0.14),
      (0.04, 0.08, 0.18),
      (0.10, 0.04, 0.16),
      (0.05, 0.05, 0.14),
      (0.16, 0.05, 0.10),
      (0.08, 0.04, 0.18),
      (0.04, 0.10, 0.16),
      (0.12, 0.04, 0.10),
    ]
  )

  // MARK: - Twilight (always dark, softer)

  /// Mid-tone evening washes — lighter than Aurora/Dusk/Nebula, still locked dark.
  private static let twilightEntries: [CounterPaletteColorData] = alwaysDarkGradientEntries(
    names: [
      "Dusk Blue", "Lavender Hour", "Mauve", "Slate Rose", "Teal Dusk",
      "Periwinkle Night", "Soft Plum", "Harbor", "Heather", "Afterlight",
    ],
    tints: [
      (0.82, 0.90, 1.00),
      (0.90, 0.84, 1.00),
      (1.00, 0.82, 0.90),
      (1.00, 0.86, 0.84),
      (0.78, 0.96, 0.94),
      (0.84, 0.88, 1.00),
      (0.96, 0.82, 0.96),
      (0.80, 0.92, 0.98),
      (0.92, 0.86, 0.98),
      (1.00, 0.88, 0.86),
    ],
    fills: [
      (0.22, 0.28, 0.42),
      (0.30, 0.24, 0.40),
      (0.36, 0.22, 0.32),
      (0.38, 0.24, 0.28),
      (0.18, 0.32, 0.34),
      (0.24, 0.28, 0.44),
      (0.34, 0.22, 0.36),
      (0.20, 0.30, 0.38),
      (0.28, 0.26, 0.40),
      (0.36, 0.26, 0.30),
    ]
  )

  /// Builds always-dark gradient slots: `fills` are adjacent gradient stops;
  /// `tints` are light companions used when Tint is on.
  private static func alwaysDarkGradientEntries(
    names: [String],
    tints: [CounterPaletteRGB],
    fills: [CounterPaletteRGB]
  ) -> [CounterPaletteColorData] {
    names.indices.map { index in
      let next = (index + 1) % names.count
      let start = fills[index]
      let end = fills[next]
      let mid = blendRGB(start, end, t: 0.5)
      return CounterPaletteColorData(
        name: names[index],
        lightRGB: tints[index],
        darkRGB: mid,
        lightGradient: nil,
        darkGradient: [start, mid, end]
      )
    }
  }

  // MARK: - Bloom (always light)

  /// Soft floral pastels — rose, peach, lilac, and mint washes.
  private static let bloomEntries: [CounterPaletteColorData] = alwaysLightGradientEntries(
    names: [
      "Petal", "Peony", "Blush", "Lilac", "Pollen",
      "Stem", "Orchid", "Nectar", "Dew", "Garden",
    ],
    tints: [
      (0.42, 0.16, 0.28),
      (0.44, 0.18, 0.14),
      (0.40, 0.14, 0.22),
      (0.30, 0.16, 0.40),
      (0.40, 0.28, 0.10),
      (0.16, 0.32, 0.22),
      (0.34, 0.14, 0.36),
      (0.42, 0.22, 0.12),
      (0.14, 0.28, 0.34),
      (0.22, 0.30, 0.18),
    ],
    fills: [
      (0.98, 0.88, 0.92),
      (0.98, 0.90, 0.86),
      (0.96, 0.86, 0.90),
      (0.92, 0.88, 0.98),
      (0.98, 0.94, 0.84),
      (0.88, 0.96, 0.90),
      (0.94, 0.88, 0.98),
      (0.98, 0.90, 0.84),
      (0.88, 0.94, 0.96),
      (0.90, 0.96, 0.88),
    ]
  )

  // MARK: - Dawn (always light)

  /// Fresh morning sky — soft gold, apricot, and pale blue.
  private static let dawnEntries: [CounterPaletteColorData] = alwaysLightGradientEntries(
    names: [
      "Daybreak", "Haze", "Apricot", "Mist", "Sunbeam",
      "Horizon", "Cloudline", "Citrine", "Air", "Morning",
    ],
    tints: [
      (0.36, 0.22, 0.10),
      (0.28, 0.24, 0.34),
      (0.40, 0.20, 0.12),
      (0.18, 0.24, 0.34),
      (0.38, 0.28, 0.08),
      (0.16, 0.26, 0.36),
      (0.22, 0.24, 0.30),
      (0.36, 0.26, 0.08),
      (0.14, 0.28, 0.36),
      (0.30, 0.20, 0.14),
    ],
    fills: [
      (0.99, 0.94, 0.86),
      (0.94, 0.92, 0.98),
      (0.99, 0.90, 0.84),
      (0.90, 0.94, 0.98),
      (0.99, 0.96, 0.84),
      (0.88, 0.94, 0.98),
      (0.94, 0.95, 0.97),
      (0.98, 0.95, 0.86),
      (0.88, 0.96, 0.98),
      (0.98, 0.92, 0.88),
    ]
  )

  // MARK: - Water (always light, deeper)

  /// Distinct water types — each slot is its own in-family gradient, not a chained spectrum.
  private static let waterEntries: [CounterPaletteColorData] = [
    alwaysLightGradientSlot(
      name: "Caribbean",
      tint: (0.06, 0.32, 0.36),
      stops: [(0.55, 0.90, 0.88), (0.42, 0.84, 0.86), (0.36, 0.76, 0.82)]
    ),
    alwaysLightGradientSlot(
      name: "Glacier",
      tint: (0.16, 0.28, 0.40),
      stops: [(0.82, 0.90, 0.96), (0.68, 0.82, 0.92), (0.52, 0.70, 0.86)]
    ),
    alwaysLightGradientSlot(
      name: "Alpine Lake",
      tint: (0.08, 0.30, 0.24),
      stops: [(0.58, 0.86, 0.78), (0.40, 0.76, 0.68), (0.28, 0.64, 0.58)]
    ),
    alwaysLightGradientSlot(
      name: "Mediterranean",
      tint: (0.08, 0.22, 0.42),
      stops: [(0.48, 0.72, 0.92), (0.34, 0.58, 0.86), (0.22, 0.44, 0.76)]
    ),
    alwaysLightGradientSlot(
      name: "Hot Spring",
      tint: (0.28, 0.30, 0.10),
      stops: [(0.86, 0.92, 0.72), (0.72, 0.86, 0.70), (0.58, 0.80, 0.74)]
    ),
    alwaysLightGradientSlot(
      name: "River",
      tint: (0.28, 0.22, 0.12),
      stops: [(0.78, 0.74, 0.58), (0.68, 0.64, 0.48), (0.56, 0.52, 0.38)]
    ),
    alwaysLightGradientSlot(
      name: "Tide Pool",
      tint: (0.12, 0.28, 0.18),
      stops: [(0.62, 0.82, 0.68), (0.48, 0.72, 0.56), (0.38, 0.60, 0.48)]
    ),
    alwaysLightGradientSlot(
      name: "Reef",
      tint: (0.32, 0.14, 0.28),
      stops: [(0.72, 0.88, 0.90), (0.78, 0.78, 0.88), (0.86, 0.70, 0.82)]
    ),
    alwaysLightGradientSlot(
      name: "Fjord",
      tint: (0.12, 0.18, 0.28),
      stops: [(0.58, 0.68, 0.78), (0.44, 0.54, 0.66), (0.32, 0.42, 0.54)]
    ),
    alwaysLightGradientSlot(
      name: "Spring",
      tint: (0.08, 0.26, 0.30),
      stops: [(0.78, 0.92, 0.94), (0.62, 0.86, 0.88), (0.48, 0.78, 0.82)]
    ),
  ]

  // MARK: - Sheen (adaptive metallic gradients)

  /// Polished metal sheens — each slot is one metal with highlight → mid → shadow stops.
  private static let sheenEntries: [CounterPaletteColorData] = [
    adaptiveGradientSlot(
      name: "Silver",
      lightStops: [(0.94, 0.95, 0.97), (0.84, 0.86, 0.90), (0.72, 0.74, 0.80)],
      darkStops: [(0.42, 0.44, 0.48), (0.28, 0.30, 0.34), (0.16, 0.17, 0.20)]
    ),
    adaptiveGradientSlot(
      name: "Gold",
      lightStops: [(0.96, 0.90, 0.68), (0.90, 0.78, 0.48), (0.80, 0.64, 0.32)],
      darkStops: [(0.48, 0.36, 0.12), (0.34, 0.24, 0.08), (0.20, 0.14, 0.04)]
    ),
    adaptiveGradientSlot(
      name: "Copper",
      lightStops: [(0.94, 0.76, 0.62), (0.86, 0.58, 0.42), (0.74, 0.42, 0.28)],
      darkStops: [(0.46, 0.24, 0.14), (0.32, 0.14, 0.08), (0.18, 0.08, 0.04)]
    ),
    adaptiveGradientSlot(
      name: "Rose Gold",
      lightStops: [(0.96, 0.84, 0.84), (0.90, 0.68, 0.70), (0.80, 0.52, 0.56)],
      darkStops: [(0.46, 0.24, 0.28), (0.32, 0.14, 0.18), (0.18, 0.08, 0.10)]
    ),
    adaptiveGradientSlot(
      name: "Bronze",
      lightStops: [(0.90, 0.78, 0.58), (0.80, 0.64, 0.42), (0.68, 0.50, 0.30)],
      darkStops: [(0.40, 0.28, 0.12), (0.28, 0.18, 0.08), (0.16, 0.10, 0.04)]
    ),
    adaptiveGradientSlot(
      name: "Gunmetal",
      lightStops: [(0.78, 0.82, 0.88), (0.64, 0.68, 0.76), (0.50, 0.54, 0.62)],
      darkStops: [(0.28, 0.32, 0.38), (0.16, 0.18, 0.24), (0.08, 0.10, 0.14)]
    ),
    adaptiveGradientSlot(
      name: "Platinum",
      lightStops: [(0.96, 0.96, 0.98), (0.88, 0.90, 0.94), (0.78, 0.80, 0.86)],
      darkStops: [(0.40, 0.42, 0.48), (0.26, 0.28, 0.32), (0.14, 0.15, 0.18)]
    ),
    adaptiveGradientSlot(
      name: "Champagne",
      lightStops: [(0.97, 0.92, 0.82), (0.90, 0.82, 0.66), (0.80, 0.70, 0.50)],
      darkStops: [(0.42, 0.34, 0.18), (0.30, 0.22, 0.10), (0.16, 0.12, 0.06)]
    ),
    adaptiveGradientSlot(
      name: "Steel",
      lightStops: [(0.82, 0.88, 0.94), (0.68, 0.76, 0.86), (0.52, 0.60, 0.72)],
      darkStops: [(0.24, 0.30, 0.40), (0.14, 0.18, 0.26), (0.06, 0.08, 0.14)]
    ),
    adaptiveGradientSlot(
      name: "Titanium",
      lightStops: [(0.90, 0.88, 0.86), (0.78, 0.76, 0.74), (0.64, 0.62, 0.60)],
      darkStops: [(0.36, 0.34, 0.32), (0.22, 0.20, 0.18), (0.12, 0.10, 0.10)]
    ),
  ]

  /// Builds always-light gradient slots: `fills` are adjacent gradient stops;
  /// `tints` are dark companions used when Tint is on.
  private static func alwaysLightGradientEntries(
    names: [String],
    tints: [CounterPaletteRGB],
    fills: [CounterPaletteRGB]
  ) -> [CounterPaletteColorData] {
    names.indices.map { index in
      let next = (index + 1) % names.count
      let start = fills[index]
      let end = fills[next]
      let mid = blendRGB(start, end, t: 0.5)
      return CounterPaletteColorData(
        name: names[index],
        lightRGB: mid,
        darkRGB: tints[index],
        lightGradient: [start, mid, end],
        darkGradient: nil
      )
    }
  }

  private static func alwaysLightGradientSlot(
    name: String,
    tint: CounterPaletteRGB,
    stops: [CounterPaletteRGB]
  ) -> CounterPaletteColorData {
    let midIndex = stops.count / 2
    let representative = stops.indices.contains(midIndex) ? stops[midIndex] : stops[0]
    return CounterPaletteColorData(
      name: name,
      lightRGB: representative,
      darkRGB: tint,
      lightGradient: stops,
      darkGradient: nil
    )
  }

  private static func adaptiveGradientSlot(
    name: String,
    lightStops: [CounterPaletteRGB],
    darkStops: [CounterPaletteRGB]
  ) -> CounterPaletteColorData {
    let lightMid = lightStops[lightStops.count / 2]
    let darkMid = darkStops[darkStops.count / 2]
    return CounterPaletteColorData(
      name: name,
      lightRGB: lightMid,
      darkRGB: darkMid,
      lightGradient: lightStops,
      darkGradient: darkStops
    )
  }

  private static func blendRGB(
    _ a: CounterPaletteRGB,
    _ b: CounterPaletteRGB,
    t: Double
  ) -> CounterPaletteRGB {
    (
      a.red + (b.red - a.red) * t,
      a.green + (b.green - a.green) * t,
      a.blue + (b.blue - a.blue) * t
    )
  }
}

/// Shared palette access for app, widgets, and watch.
///
/// Slot colours come from the currently selected `CounterColorPack`, so all
/// targets stay in sync when the user changes pack in Settings.
enum CounterPaletteData {
  static let slotCount = 10

  static var selectedPack: CounterColorPack {
    AppAppearancePreference.colorPack
  }

  static var appearanceLock: CounterColorPackAppearanceLock {
    selectedPack.appearanceLock
  }

  static var forcesDarkAppearance: Bool {
    selectedPack.forcesDarkAppearance
  }

  static var forcesLightAppearance: Bool {
    selectedPack.forcesLightAppearance
  }

  static var entries: [CounterPaletteColorData] {
    selectedPack.entries
  }

  static func entry(at index: Int) -> CounterPaletteColorData {
    let normalized = ((index % slotCount) + slotCount) % slotCount
    return entries[normalized]
  }

  static func resolvedScheme(for appScheme: ColorScheme) -> ColorScheme {
    selectedPack.resolvedScheme(for: appScheme)
  }
}
