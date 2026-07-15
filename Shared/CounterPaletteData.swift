import Foundation

/// Raw RGB values for the 20-slot counter palette.
///
/// This is the single source of truth for palette colors. Both the app's
/// `CounterPaletteTokens` (which builds `SwiftUI.Color` + naming/sorting for
/// the settings swatch grid) and the widget extension's `WidgetPalette`
/// (which can't depend on `Counter/Design`) build their colors from this
/// list, so the two color tables can no longer drift apart.
struct CounterPaletteColorData {
  let name: String
  let lightRGB: (red: Double, green: Double, blue: Double)
  let darkRGB: (red: Double, green: Double, blue: Double)
}

enum CounterPaletteData {
  static let slotCount = 20

  static let entries: [CounterPaletteColorData] = [
    CounterPaletteColorData(
      name: "Yellow",
      lightRGB: (0.97, 0.91, 0.45),
      darkRGB: (0.24, 0.22, 0.10)
    ),
    CounterPaletteColorData(
      name: "Lavender",
      lightRGB: (0.84, 0.77, 0.96),
      darkRGB: (0.22, 0.18, 0.30)
    ),
    CounterPaletteColorData(
      name: "Mint",
      lightRGB: (0.71, 0.92, 0.84),
      darkRGB: (0.12, 0.26, 0.22)
    ),
    CounterPaletteColorData(
      name: "Peach",
      lightRGB: (1.0, 0.85, 0.76),
      darkRGB: (0.30, 0.18, 0.14)
    ),
    CounterPaletteColorData(
      name: "Sky",
      lightRGB: (0.78, 0.90, 0.96),
      darkRGB: (0.12, 0.22, 0.28)
    ),
    CounterPaletteColorData(
      name: "Rose",
      lightRGB: (0.96, 0.78, 0.84),
      darkRGB: (0.30, 0.14, 0.20)
    ),
    CounterPaletteColorData(
      name: "Lime",
      lightRGB: (0.89, 0.94, 0.64),
      darkRGB: (0.20, 0.24, 0.10)
    ),
    CounterPaletteColorData(
      name: "Coral",
      lightRGB: (1.0, 0.71, 0.64),
      darkRGB: (0.32, 0.14, 0.12)
    ),
    CounterPaletteColorData(
      name: "Periwinkle",
      lightRGB: (0.77, 0.83, 0.96),
      darkRGB: (0.14, 0.18, 0.30)
    ),
    CounterPaletteColorData(
      name: "Sand",
      lightRGB: (0.93, 0.88, 0.78),
      darkRGB: (0.24, 0.20, 0.16)
    ),
    CounterPaletteColorData(
      name: "White",
      lightRGB: (0.99, 0.99, 1.0),
      darkRGB: (0.22, 0.22, 0.24)
    ),
    CounterPaletteColorData(
      name: "Fog",
      lightRGB: (0.90, 0.91, 0.93),
      darkRGB: (0.26, 0.27, 0.29)
    ),
    CounterPaletteColorData(
      name: "Stone",
      lightRGB: (0.86, 0.84, 0.80),
      darkRGB: (0.22, 0.20, 0.18)
    ),
    CounterPaletteColorData(
      name: "Teal",
      lightRGB: (0.62, 0.88, 0.84),
      darkRGB: (0.10, 0.24, 0.22)
    ),
    CounterPaletteColorData(
      name: "Indigo",
      lightRGB: (0.72, 0.74, 0.96),
      darkRGB: (0.16, 0.14, 0.32)
    ),
    CounterPaletteColorData(
      name: "Plum",
      lightRGB: (0.88, 0.72, 0.88),
      darkRGB: (0.26, 0.14, 0.26)
    ),
    CounterPaletteColorData(
      name: "Berry",
      lightRGB: (0.92, 0.68, 0.82),
      darkRGB: (0.28, 0.12, 0.22)
    ),
    CounterPaletteColorData(
      name: "Olive",
      lightRGB: (0.82, 0.86, 0.62),
      darkRGB: (0.18, 0.22, 0.10)
    ),
    CounterPaletteColorData(
      name: "Apricot",
      lightRGB: (1.0, 0.82, 0.68),
      darkRGB: (0.32, 0.20, 0.14)
    ),
    CounterPaletteColorData(
      name: "Aqua",
      lightRGB: (0.68, 0.92, 0.96),
      darkRGB: (0.10, 0.22, 0.26)
    )
  ]

  static func entry(at index: Int) -> CounterPaletteColorData {
    let normalized = ((index % slotCount) + slotCount) % slotCount
    return entries[normalized]
  }
}
