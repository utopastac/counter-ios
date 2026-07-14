import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct CounterPaletteSlot: Equatable, Identifiable {
  let id: Int
  let name: String
  let lightBackground: Color
  let darkBackground: Color

  func background(for scheme: ColorScheme) -> Color {
    scheme == .dark ? darkBackground : lightBackground
  }

  func foreground(for scheme: ColorScheme) -> Color {
    scheme == .dark ? BaseColor.white : BaseColor.black
  }

  func mutedForeground(for scheme: ColorScheme) -> Color {
    foreground(for: scheme).opacity(scheme == .dark ? 0.72 : 0.62)
  }

  func subtleForeground(for scheme: ColorScheme) -> Color {
    foreground(for: scheme).opacity(0.1)
  }

  func buttonForeground(for scheme: ColorScheme) -> Color {
    scheme == .dark ? BaseColor.black : BaseColor.white
  }

  /// Muted track color for progress rings sitting on the card background.
  func progressRingTrack(for scheme: ColorScheme) -> Color {
    Self.darken(background(for: scheme), amount: scheme == .dark ? 0.22 : 0.16)
  }

  private static func darken(_ color: Color, amount: CGFloat) -> Color {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return color.opacity(1 - amount * 0.5)
    }

    let factor = 1 - amount
    return Color(
      red: red * factor,
      green: green * factor,
      blue: blue * factor,
      opacity: alpha
    )
  }
}

enum CounterPaletteTokens {
  static let slotCount = 20

  static let slots: [CounterPaletteSlot] = [
    CounterPaletteSlot(
      id: 0,
      name: "Yellow",
      lightBackground: Color(red: 0.97, green: 0.91, blue: 0.45),
      darkBackground: Color(red: 0.24, green: 0.22, blue: 0.10)
    ),
    CounterPaletteSlot(
      id: 1,
      name: "Lavender",
      lightBackground: Color(red: 0.84, green: 0.77, blue: 0.96),
      darkBackground: Color(red: 0.22, green: 0.18, blue: 0.30)
    ),
    CounterPaletteSlot(
      id: 2,
      name: "Mint",
      lightBackground: Color(red: 0.71, green: 0.92, blue: 0.84),
      darkBackground: Color(red: 0.12, green: 0.26, blue: 0.22)
    ),
    CounterPaletteSlot(
      id: 3,
      name: "Peach",
      lightBackground: Color(red: 1.0, green: 0.85, blue: 0.76),
      darkBackground: Color(red: 0.30, green: 0.18, blue: 0.14)
    ),
    CounterPaletteSlot(
      id: 4,
      name: "Sky",
      lightBackground: Color(red: 0.78, green: 0.90, blue: 0.96),
      darkBackground: Color(red: 0.12, green: 0.22, blue: 0.28)
    ),
    CounterPaletteSlot(
      id: 5,
      name: "Rose",
      lightBackground: Color(red: 0.96, green: 0.78, blue: 0.84),
      darkBackground: Color(red: 0.30, green: 0.14, blue: 0.20)
    ),
    CounterPaletteSlot(
      id: 6,
      name: "Lime",
      lightBackground: Color(red: 0.89, green: 0.94, blue: 0.64),
      darkBackground: Color(red: 0.20, green: 0.24, blue: 0.10)
    ),
    CounterPaletteSlot(
      id: 7,
      name: "Coral",
      lightBackground: Color(red: 1.0, green: 0.71, blue: 0.64),
      darkBackground: Color(red: 0.32, green: 0.14, blue: 0.12)
    ),
    CounterPaletteSlot(
      id: 8,
      name: "Periwinkle",
      lightBackground: Color(red: 0.77, green: 0.83, blue: 0.96),
      darkBackground: Color(red: 0.14, green: 0.18, blue: 0.30)
    ),
    CounterPaletteSlot(
      id: 9,
      name: "Sand",
      lightBackground: Color(red: 0.93, green: 0.88, blue: 0.78),
      darkBackground: Color(red: 0.24, green: 0.20, blue: 0.16)
    ),
    CounterPaletteSlot(
      id: 10,
      name: "White",
      lightBackground: Color(red: 0.99, green: 0.99, blue: 1.0),
      darkBackground: Color(red: 0.22, green: 0.22, blue: 0.24)
    ),
    CounterPaletteSlot(
      id: 11,
      name: "Fog",
      lightBackground: Color(red: 0.90, green: 0.91, blue: 0.93),
      darkBackground: Color(red: 0.26, green: 0.27, blue: 0.29)
    ),
    CounterPaletteSlot(
      id: 12,
      name: "Stone",
      lightBackground: Color(red: 0.86, green: 0.84, blue: 0.80),
      darkBackground: Color(red: 0.22, green: 0.20, blue: 0.18)
    ),
    CounterPaletteSlot(
      id: 13,
      name: "Teal",
      lightBackground: Color(red: 0.62, green: 0.88, blue: 0.84),
      darkBackground: Color(red: 0.10, green: 0.24, blue: 0.22)
    ),
    CounterPaletteSlot(
      id: 14,
      name: "Indigo",
      lightBackground: Color(red: 0.72, green: 0.74, blue: 0.96),
      darkBackground: Color(red: 0.16, green: 0.14, blue: 0.32)
    ),
    CounterPaletteSlot(
      id: 15,
      name: "Plum",
      lightBackground: Color(red: 0.88, green: 0.72, blue: 0.88),
      darkBackground: Color(red: 0.26, green: 0.14, blue: 0.26)
    ),
    CounterPaletteSlot(
      id: 16,
      name: "Berry",
      lightBackground: Color(red: 0.92, green: 0.68, blue: 0.82),
      darkBackground: Color(red: 0.28, green: 0.12, blue: 0.22)
    ),
    CounterPaletteSlot(
      id: 17,
      name: "Olive",
      lightBackground: Color(red: 0.82, green: 0.86, blue: 0.62),
      darkBackground: Color(red: 0.18, green: 0.22, blue: 0.10)
    ),
    CounterPaletteSlot(
      id: 18,
      name: "Apricot",
      lightBackground: Color(red: 1.0, green: 0.82, blue: 0.68),
      darkBackground: Color(red: 0.32, green: 0.20, blue: 0.14)
    ),
    CounterPaletteSlot(
      id: 19,
      name: "Aqua",
      lightBackground: Color(red: 0.68, green: 0.92, blue: 0.96),
      darkBackground: Color(red: 0.10, green: 0.22, blue: 0.26)
    )
  ]

  /// Palette slots ordered for display: neutrals first (brightest to darkest), then chromatic hues.
  static var slotsSortedByColor: [CounterPaletteSlot] {
    slots.sorted { compareColorOrder($0.lightBackground, $1.lightBackground) }
  }

  static func slot(at index: Int) -> CounterPaletteSlot {
    let normalized = ((index % slotCount) + slotCount) % slotCount
    return slots[normalized]
  }

  private static func compareColorOrder(_ lhs: Color, _ rhs: Color) -> Bool {
    let left = colorSortKey(for: lhs)
    let right = colorSortKey(for: rhs)

    if left.group != right.group {
      return left.group < right.group
    }

    if left.group == 0 {
      return left.brightness > right.brightness
    }

    return left.hue < right.hue
  }

  private static func colorSortKey(for color: Color) -> (group: Int, hue: CGFloat, brightness: CGFloat) {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    #if canImport(UIKit)
    guard UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
      return (2, 0, 0)
    }
    #else
    return (2, 0, 0)
    #endif

    if saturation < 0.15 {
      return (0, 0, brightness)
    }

    return (1, hue, brightness)
  }
}
