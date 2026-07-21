import Foundation

/// Raw RGB values for a single palette slot within a colour pack.
struct CounterPaletteColorData {
  let name: String
  let lightRGB: (red: Double, green: Double, blue: Double)
  let darkRGB: (red: Double, green: Double, blue: Double)
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
    }
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

  static var entries: [CounterPaletteColorData] {
    selectedPack.entries
  }

  static func entry(at index: Int) -> CounterPaletteColorData {
    let normalized = ((index % slotCount) + slotCount) % slotCount
    return entries[normalized]
  }
}
