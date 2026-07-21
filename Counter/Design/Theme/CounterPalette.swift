import SwiftUI

/// Per-counter theme derived from the shared counter palette.
struct CounterAccent: Equatable {
  let paletteIndex: Int
  /// Captured so pack changes invalidate environment equality and refresh themed views.
  let colorPackRaw: String

  init(paletteIndex: Int, colorPackRaw: String = AppAppearancePreference.colorPack.rawValue) {
    self.paletteIndex = paletteIndex
    self.colorPackRaw = colorPackRaw
  }

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
