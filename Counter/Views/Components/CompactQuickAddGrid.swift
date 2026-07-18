import SwiftUI

struct CompactQuickAddGrid: View {
  let values: [Double]
  let defaultPresets: [Double]
  var buttonHeight: CGFloat = SizeToken.quickAddHeight
  let onTap: (Double) -> Void
  let onCustom: () -> Void

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: SizeToken.gridSpacing), count: SizeToken.gridColumnCount)
  }

  private var displayValues: [Double] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaultPresets)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SizeToken.gridSpacing) {
      ForEach(Array(displayValues.enumerated()), id: \.offset) { _, value in
        CounterActionButton(CounterFormatting.amount(value), height: buttonHeight) {
          onTap(value)
        }
      }

      CounterActionButton(icon: .ellipsis, height: buttonHeight) {
        onCustom()
      }
    }
  }
}
