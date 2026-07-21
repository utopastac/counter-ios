import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct WidgetPaletteSlot {
  let lightBackground: Color
  let darkBackground: Color

  func background(for scheme: ColorScheme) -> Color {
    scheme == .dark ? darkBackground : lightBackground
  }

  func foreground(for scheme: ColorScheme) -> Color {
    if AppAppearancePreference.isTintEnabled {
      return scheme == .dark ? lightBackground : darkBackground
    }
    return scheme == .dark ? .white : .black
  }

  func mutedForeground(for scheme: ColorScheme) -> Color {
    foreground(for: scheme).opacity(scheme == .dark ? 0.72 : 0.62)
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
    Self.darken(background(for: scheme), amount: scheme == .dark ? 0.22 : 0.16)
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
    CounterPaletteData.entries.map { entry in
      WidgetPaletteSlot(
        lightBackground: Color(red: entry.lightRGB.red, green: entry.lightRGB.green, blue: entry.lightRGB.blue),
        darkBackground: Color(red: entry.darkRGB.red, green: entry.darkRGB.green, blue: entry.darkRGB.blue)
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
  let foreground: Color
  let mutedForeground: Color
  let buttonFill: Color
  let buttonText: Color
  let ringTrack: Color
  let ringOverfillOutline: Color

  init(paletteIndex: Int, colorScheme: ColorScheme) {
    let slot = WidgetPalette.slot(at: paletteIndex)
    background = slot.background(for: colorScheme)
    foreground = slot.foreground(for: colorScheme)
    mutedForeground = slot.mutedForeground(for: colorScheme)
    buttonFill = slot.buttonFill(for: colorScheme)
    buttonText = slot.buttonText(for: colorScheme)
    ringTrack = slot.progressRingTrack(for: colorScheme)
    ringOverfillOutline = slot.progressRingOverfillOutline(for: colorScheme)
  }
}
