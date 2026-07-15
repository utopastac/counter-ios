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
  static let slotCount = CounterPaletteData.slotCount

  /// Built from the shared `CounterPaletteData` so the app and widget
  /// extension can never end up with mismatched palette colors.
  static let slots: [CounterPaletteSlot] = CounterPaletteData.entries.enumerated().map { index, entry in
    CounterPaletteSlot(
      id: index,
      name: entry.name,
      lightBackground: Color(red: entry.lightRGB.red, green: entry.lightRGB.green, blue: entry.lightRGB.blue),
      darkBackground: Color(red: entry.darkRGB.red, green: entry.darkRGB.green, blue: entry.darkRGB.blue)
    )
  }

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
