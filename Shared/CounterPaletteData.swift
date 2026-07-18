import Foundation

/// Raw RGB values for the counter palette.
///
/// This is the single source of truth for palette colors. Both the app's
/// `CounterPaletteTokens` (which builds `SwiftUI.Color` + naming/sorting for
/// the settings swatch grid) and the widget extension's `WidgetPalette`
/// (which can't depend on `Counter/Design`) build their colors from this
/// list, so the two color tables can no longer drift apart.
///
/// Colors are muted and desaturated so cards feel calm rather than candy-like.
/// Slot order is chosen so consecutive indices (new-counter defaults) alternate
/// cool / warm / green / neutral families for clearer separation.
struct CounterPaletteColorData {
  let name: String
  let lightRGB: (red: Double, green: Double, blue: Double)
  let darkRGB: (red: Double, green: Double, blue: Double)
}

enum CounterPaletteData {
  static let slotCount = 10

  static let entries: [CounterPaletteColorData] = [
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

  static func entry(at index: Int) -> CounterPaletteColorData {
    let normalized = ((index % slotCount) + slotCount) % slotCount
    return entries[normalized]
  }
}
