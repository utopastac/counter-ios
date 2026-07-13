import SwiftUI

enum CounterTheme {
  struct Palette {
    let top: Color
    let bottom: Color
    let accent: Color

    var gradient: LinearGradient {
      LinearGradient(
        colors: [top, bottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  static let calories = Palette(
    top: Color(red: 0.45, green: 0.18, blue: 0.08),
    bottom: Color(red: 0.08, green: 0.10, blue: 0.22),
    accent: Color(red: 1.0, green: 0.55, blue: 0.25)
  )

  static let addNew = Palette(
    top: Color(red: 0.12, green: 0.14, blue: 0.18),
    bottom: Color(red: 0.05, green: 0.06, blue: 0.09),
    accent: Color.white.opacity(0.85)
  )

  static func forCounter(named name: String) -> Palette {
    let hash = abs(name.hashValue)
    let hue = Double(hash % 360) / 360.0
    return Palette(
      top: Color(hue: hue, saturation: 0.55, brightness: 0.35),
      bottom: Color(hue: (hue + 0.12).truncatingRemainder(dividingBy: 1), saturation: 0.45, brightness: 0.12),
      accent: Color(hue: hue, saturation: 0.65, brightness: 0.92)
    )
  }
}

struct CounterPageBackground: View {
  let palette: CounterTheme.Palette

  var body: some View {
    ZStack {
      palette.gradient
      RadialGradient(
        colors: [palette.accent.opacity(0.25), .clear],
        center: .topTrailing,
        startRadius: 40,
        endRadius: 420
      )
    }
    .ignoresSafeArea()
  }
}
