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
    ringTrack = background.opacity(0.72)
  }
}
