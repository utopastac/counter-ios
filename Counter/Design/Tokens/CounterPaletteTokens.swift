import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct CounterPaletteSlot: Equatable, Identifiable {
  let id: Int
  let name: String
  let lightBackground: Color
  let darkBackground: Color
  let lightGradient: [Color]?
  let darkGradient: [Color]?
  /// Locks fills/foregrounds to light or dark, or follows the app scheme.
  let appearanceLock: CounterColorPackAppearanceLock

  var hasGradient: Bool {
    (lightGradient?.count ?? 0) >= 2 || (darkGradient?.count ?? 0) >= 2
  }

  private func effectiveScheme(_ scheme: ColorScheme) -> ColorScheme {
    appearanceLock.resolvedScheme(for: scheme)
  }

  /// Solid representative colour — used for pager RGB lerp, ring darken, and glass tint.
  func background(for scheme: ColorScheme) -> Color {
    effectiveScheme(scheme) == .dark ? darkBackground : lightBackground
  }

  /// Visible card / page fill — linear gradient when the pack defines stops.
  func backgroundStyle(
    for scheme: ColorScheme,
    startPoint: UnitPoint = .topLeading,
    endPoint: UnitPoint = .bottomTrailing
  ) -> AnyShapeStyle {
    let resolved = effectiveScheme(scheme)
    let stops = resolved == .dark ? darkGradient : lightGradient
    if let stops, stops.count >= 2 {
      return AnyShapeStyle(
        LinearGradient(colors: stops, startPoint: startPoint, endPoint: endPoint)
      )
    }
    return AnyShapeStyle(background(for: scheme))
  }

  /// Opposite-scheme palette colour (dark companion in light mode, light in dark).
  func inverseBackground(for scheme: ColorScheme) -> Color {
    effectiveScheme(scheme) == .dark ? lightBackground : darkBackground
  }

  func foreground(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    if AppAppearancePreference.isTintEnabled {
      // Opposite-scheme palette colour: dark tint on light cards, light tint on dark.
      return inverseBackground(for: scheme)
    }
    return resolved == .dark ? BaseColor.white : BaseColor.black
  }

  func subtleForeground(for scheme: ColorScheme) -> Color {
    foreground(for: scheme).opacity(0.1)
  }

  func buttonForeground(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    if AppAppearancePreference.isTintEnabled {
      return background(for: scheme)
    }
    return resolved == .dark ? BaseColor.black : BaseColor.white
  }

  /// Muted track color for progress rings sitting on the card background.
  func progressRingTrack(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    return Self.darken(background(for: scheme), amount: resolved == .dark ? 0.22 : 0.16)
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
  static var slots: [CounterPaletteSlot] {
    let appearanceLock = CounterPaletteData.appearanceLock
    return CounterPaletteData.entries.enumerated().map { index, entry in
      CounterPaletteSlot(
        id: index,
        name: entry.name,
        lightBackground: Color(
          red: entry.lightRGB.red,
          green: entry.lightRGB.green,
          blue: entry.lightRGB.blue
        ),
        darkBackground: Color(
          red: entry.darkRGB.red,
          green: entry.darkRGB.green,
          blue: entry.darkRGB.blue
        ),
        lightGradient: entry.lightGradient?.map {
          Color(red: $0.red, green: $0.green, blue: $0.blue)
        },
        darkGradient: entry.darkGradient?.map {
          Color(red: $0.red, green: $0.green, blue: $0.blue)
        },
        appearanceLock: appearanceLock
      )
    }
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
