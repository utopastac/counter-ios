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
    scheme == .dark ? .white : .black
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
}

enum WidgetPalette {
  /// Built from the shared `CounterPaletteData` so the widget extension's
  /// colors can never drift from the app's `CounterPaletteTokens`.
  static let slots: [WidgetPaletteSlot] = CounterPaletteData.entries.map { entry in
    WidgetPaletteSlot(
      lightBackground: Color(red: entry.lightRGB.red, green: entry.lightRGB.green, blue: entry.lightRGB.blue),
      darkBackground: Color(red: entry.darkRGB.red, green: entry.darkRGB.green, blue: entry.darkRGB.blue)
    )
  }

  static func slot(at index: Int) -> WidgetPaletteSlot {
    let normalized = ((index % slots.count) + slots.count) % slots.count
    return slots[normalized]
  }

  static func paletteIndex(forCustomCounterAt index: Int) -> Int {
    index % slots.count
  }
}

struct WidgetThemeColors {
  let background: Color
  let foreground: Color
  let mutedForeground: Color
  let buttonFill: Color
  let buttonText: Color

  init(paletteIndex: Int, colorScheme: ColorScheme) {
    let slot = WidgetPalette.slot(at: paletteIndex)
    background = slot.background(for: colorScheme)
    foreground = slot.foreground(for: colorScheme)
    mutedForeground = slot.mutedForeground(for: colorScheme)
    buttonFill = slot.buttonFill(for: colorScheme)
    buttonText = slot.buttonText(for: colorScheme)
  }
}
