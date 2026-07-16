import SwiftUI

struct WatchThemeColors {
  let background: Color
  let foreground: Color
  let mutedForeground: Color
  let ringTrack: Color

  init(paletteIndex: Int) {
    let entry = CounterPaletteData.entry(at: paletteIndex)
    background = Color(
      red: entry.darkRGB.red,
      green: entry.darkRGB.green,
      blue: entry.darkRGB.blue
    )
    foreground = .white
    mutedForeground = .white.opacity(0.72)
    // Darken (rather than fade) the background so the track reads as a
    // visible ring against a same-colored page background — matching
    // `CounterPaletteSlot.progressRingTrack`.
    let darkenFactor: Double = 0.78
    ringTrack = Color(
      red: entry.darkRGB.red * darkenFactor,
      green: entry.darkRGB.green * darkenFactor,
      blue: entry.darkRGB.blue * darkenFactor
    )
  }
}
