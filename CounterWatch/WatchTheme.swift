import SwiftUI

struct WatchThemeColors {
  let background: Color
  let backgroundStyle: AnyShapeStyle
  let foreground: Color
  let mutedForeground: Color
  let ringTrack: Color

  init(paletteIndex: Int) {
    let entry = CounterPaletteData.entry(at: paletteIndex)
    // Watch chrome is dark by default; always-light packs still resolve to light fills.
    let scheme = CounterPaletteData.resolvedScheme(for: .dark)
    let rgb = scheme == .dark ? entry.darkRGB : entry.lightRGB
    background = entry.solidColor(for: scheme)
    backgroundStyle = entry.backgroundStyle(for: scheme)
    if AppAppearancePreference.isTintEnabled {
      let tintScheme: ColorScheme = scheme == .dark ? .light : .dark
      let tint = entry.solidColor(for: tintScheme)
      foreground = tint
      mutedForeground = tint.opacity(0.72)
    } else {
      foreground = scheme == .dark ? .white : .black
      mutedForeground = foreground.opacity(0.72)
    }
    // Darken (rather than fade) the background so the track reads as a
    // visible ring against a same-colored page background — matching
    // `CounterPaletteSlot.progressRingTrack`.
    let darkenFactor: Double = 0.78
    ringTrack = Color(
      red: rgb.red * darkenFactor,
      green: rgb.green * darkenFactor,
      blue: rgb.blue * darkenFactor
    )
  }
}
