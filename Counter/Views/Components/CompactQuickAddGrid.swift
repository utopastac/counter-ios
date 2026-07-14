import SwiftUI

struct CompactQuickAddGrid: View {
  let values: [Int]
  let defaultPresets: [Int]
  let onTap: (Int) -> Void
  let onCustom: () -> Void

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing), count: SizeToken.gridColumnCount)
  }

  private var displayValues: [Int] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaultPresets)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(displayValues, id: \.self) { value in
        CounterActionButton("\(value)") {
          onTap(value)
        }
      }

      CounterActionButton(icon: .ellipsis) {
        onCustom()
      }
    }
  }
}
