import SwiftUI

/// Per-counter theme derived from the shared 20-slot palette.
struct CounterAccent: Equatable {
  let paletteIndex: Int

  var palette: CounterPaletteSlot {
    CounterPaletteTokens.slot(at: paletteIndex)
  }

  static let calories = CounterAccent(paletteIndex: 0)

  static func forCustomCounter(at index: Int) -> CounterAccent {
    CounterAccent(paletteIndex: index % CounterPaletteTokens.slotCount)
  }

  static func forCounter(_ counter: CustomCounter) -> CounterAccent {
    CounterAccent(paletteIndex: counter.effectivePaletteIndex)
  }

  /// Legacy accessor — prefer `palette`.
  var accent: Color {
    palette.lightBackground
  }
}

enum CounterTheme {
  static var calories: CounterAccent { CounterAccent.calories }

  static func forCustomCounter(at index: Int) -> CounterAccent {
    CounterAccent.forCustomCounter(at: index)
  }

  static func forCounter(named name: String) -> CounterAccent {
    CounterAccent(paletteIndex: abs(name.hashValue) % CounterPaletteTokens.slotCount)
  }
}

typealias CounterPalette = CounterAccent

enum CounterPaletteLibrary {
  static var calories: CounterAccent { CounterAccent.calories }

  static func forCustomCounter(at index: Int) -> CounterAccent {
    CounterAccent.forCustomCounter(at: index)
  }

  static func forCounter(named name: String) -> CounterAccent {
    CounterTheme.forCounter(named: name)
  }
}
