import SwiftUI

/// Optional per-counter accent used for progress rings and highlights.
struct CounterAccent: Equatable {
  let accent: Color

  static let calories = CounterAccent(accent: BaseColor.Orange.orange500)
  static let `default` = CounterAccent(accent: BaseColor.Brand.blue500)

  static func forCounter(named name: String) -> CounterAccent {
    let hash = abs(name.hashValue)
    let hue = Double(hash % 360) / 360.0
    return CounterAccent(
      accent: Color(hue: hue, saturation: 0.42, brightness: 0.72)
    )
  }
}

// Backward-compatible aliases used across the app.
enum CounterTheme {
  typealias Palette = CounterAccent

  static var calories: CounterAccent { CounterAccent.calories }
  static func forCounter(named name: String) -> CounterAccent {
    CounterAccent.forCounter(named: name)
  }
}

typealias CounterPalette = CounterAccent

enum CounterPaletteLibrary {
  static var calories: CounterAccent { CounterAccent.calories }
  static func forCounter(named name: String) -> CounterAccent {
    CounterAccent.forCounter(named: name)
  }
}
