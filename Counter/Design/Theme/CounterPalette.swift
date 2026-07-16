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
    CounterAccent(
      paletteIndex: AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex)
    )
  }
}
