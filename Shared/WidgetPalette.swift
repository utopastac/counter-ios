import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct WidgetPaletteSlot {
  let lightBackground: Color
  let darkBackground: Color
  let lightGradient: [Color]?
  let darkGradient: [Color]?
  let appearanceLock: CounterColorPackAppearanceLock

  var hasGradient: Bool {
    (lightGradient?.count ?? 0) >= 2 || (darkGradient?.count ?? 0) >= 2
  }

  private func effectiveScheme(_ scheme: ColorScheme) -> ColorScheme {
    appearanceLock.resolvedScheme(for: scheme)
  }

  func background(for scheme: ColorScheme) -> Color {
    effectiveScheme(scheme) == .dark ? darkBackground : lightBackground
  }

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

  func foreground(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    if AppAppearancePreference.isTintEnabled {
      return resolved == .dark ? lightBackground : darkBackground
    }
    return resolved == .dark ? .white : .black
  }

  func mutedForeground(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    return foreground(for: scheme).opacity(resolved == .dark ? 0.72 : 0.62)
  }

  func buttonFill(for scheme: ColorScheme) -> Color {
    foreground(for: scheme)
  }

  func buttonText(for scheme: ColorScheme) -> Color {
    background(for: scheme)
  }

  /// Muted track color for progress rings sitting on the card background — mirrors
  /// `CounterPaletteSlot.progressRingTrack(for:)` so the widget's ring reads identically to
  /// the app's, without pulling the app-only `Counter/Design` module into this target.
  func progressRingTrack(for scheme: ColorScheme) -> Color {
    let resolved = effectiveScheme(scheme)
    return Self.darken(background(for: scheme), amount: resolved == .dark ? 0.22 : 0.16)
  }

  /// Background the overfill halo cuts back down to — same "cut-out" rationale as
  /// `CounterPaletteSlot`'s equivalent.
  func progressRingOverfillOutline(for scheme: ColorScheme) -> Color {
    background(for: scheme)
  }

  private static func darken(_ color: Color, amount: CGFloat) -> Color {
    #if canImport(UIKit)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return color.opacity(1 - amount * 0.5)
    }

    let factor = 1 - amount
    return Color(red: red * factor, green: green * factor, blue: blue * factor, opacity: alpha)
    #else
    return color.opacity(1 - amount * 0.5)
    #endif
  }
}

enum WidgetPalette {
  /// Built from the shared `CounterPaletteData` so the widget extension's
  /// colors can never drift from the app's `CounterPaletteTokens`.
  static var slots: [WidgetPaletteSlot] {
    let appearanceLock = CounterPaletteData.appearanceLock
    return CounterPaletteData.entries.map { entry in
      WidgetPaletteSlot(
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

  static func slot(at index: Int) -> WidgetPaletteSlot {
    let count = max(slots.count, 1)
    let normalized = ((index % count) + count) % count
    return slots[normalized]
  }

  static func paletteIndex(forCustomCounterAt index: Int) -> Int {
    index % CounterPaletteData.slotCount
  }
}

struct WidgetThemeColors {
  let background: Color
  let backgroundStyle: AnyShapeStyle
  let foreground: Color
  let mutedForeground: Color
  let buttonFill: Color
  let buttonText: Color
  let ringTrack: Color
  let ringOverfillOutline: Color

  init(paletteIndex: Int, colorScheme: ColorScheme) {
    let slot = WidgetPalette.slot(at: paletteIndex)
    background = slot.background(for: colorScheme)
    backgroundStyle = slot.backgroundStyle(for: colorScheme)
    foreground = slot.foreground(for: colorScheme)
    mutedForeground = slot.mutedForeground(for: colorScheme)
    buttonFill = slot.buttonFill(for: colorScheme)
    buttonText = slot.buttonText(for: colorScheme)
    ringTrack = slot.progressRingTrack(for: colorScheme)
    ringOverfillOutline = slot.progressRingOverfillOutline(for: colorScheme)
  }
}
