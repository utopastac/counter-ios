import SwiftUI

struct WatchQuickAddGrid: View {
  let values: [Int]
  let defaultPresets: [Int]
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  /// Fills up to a full grid from `defaultPresets` when `values` doesn't have enough on its
  /// own, matching the iPhone quick-add grid's fill policy — this used to just normalize
  /// `values` in isolation, which showed a sparser grid on the Watch than on the iPhone for
  /// the same counter.
  private var displayValues: [Int] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaultPresets)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(Array(displayValues.enumerated()), id: \.offset) { _, value in
        Button("\(value)") {
          onTap(value)
        }
        .buttonStyle(.bordered)
        .font(.caption)
      }
    }
  }
}

#Preview {
  WatchQuickAddGrid(
    values: [10, 20, 50, 100],
    defaultPresets: QuickAddConfiguration.defaultCounterPresets
  ) { _ in }
}
