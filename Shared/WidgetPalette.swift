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
  static let slots: [WidgetPaletteSlot] = [
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.97, green: 0.91, blue: 0.45),
      darkBackground: Color(red: 0.24, green: 0.22, blue: 0.10)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.84, green: 0.77, blue: 0.96),
      darkBackground: Color(red: 0.22, green: 0.18, blue: 0.30)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.71, green: 0.92, blue: 0.84),
      darkBackground: Color(red: 0.12, green: 0.26, blue: 0.22)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 1.0, green: 0.85, blue: 0.76),
      darkBackground: Color(red: 0.30, green: 0.18, blue: 0.14)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.78, green: 0.90, blue: 0.96),
      darkBackground: Color(red: 0.12, green: 0.22, blue: 0.28)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.96, green: 0.78, blue: 0.84),
      darkBackground: Color(red: 0.30, green: 0.14, blue: 0.20)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.89, green: 0.94, blue: 0.64),
      darkBackground: Color(red: 0.20, green: 0.24, blue: 0.10)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 1.0, green: 0.71, blue: 0.64),
      darkBackground: Color(red: 0.32, green: 0.14, blue: 0.12)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.77, green: 0.83, blue: 0.96),
      darkBackground: Color(red: 0.14, green: 0.18, blue: 0.30)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.93, green: 0.88, blue: 0.78),
      darkBackground: Color(red: 0.24, green: 0.20, blue: 0.16)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.99, green: 0.99, blue: 1.0),
      darkBackground: Color(red: 0.22, green: 0.22, blue: 0.24)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.90, green: 0.91, blue: 0.93),
      darkBackground: Color(red: 0.26, green: 0.27, blue: 0.29)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.86, green: 0.84, blue: 0.80),
      darkBackground: Color(red: 0.22, green: 0.20, blue: 0.18)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.62, green: 0.88, blue: 0.84),
      darkBackground: Color(red: 0.10, green: 0.24, blue: 0.22)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.72, green: 0.74, blue: 0.96),
      darkBackground: Color(red: 0.16, green: 0.14, blue: 0.32)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.88, green: 0.72, blue: 0.88),
      darkBackground: Color(red: 0.26, green: 0.14, blue: 0.26)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.92, green: 0.68, blue: 0.82),
      darkBackground: Color(red: 0.28, green: 0.12, blue: 0.22)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.82, green: 0.86, blue: 0.62),
      darkBackground: Color(red: 0.18, green: 0.22, blue: 0.10)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 1.0, green: 0.82, blue: 0.68),
      darkBackground: Color(red: 0.32, green: 0.20, blue: 0.14)
    ),
    WidgetPaletteSlot(
      lightBackground: Color(red: 0.68, green: 0.92, blue: 0.96),
      darkBackground: Color(red: 0.10, green: 0.22, blue: 0.26)
    )
  ]

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
