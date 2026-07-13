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
        GlassButton("\(value)") {
          onTap(value)
        }
      }

      GlassButton(systemImage: "ellipsis") {
        onCustom()
      }
    }
  }
}

#Preview("Dark") {
  ZStack {
    CounterPageBackground()
    CompactQuickAddGrid(
      values: [10, 20, 50, 100, 200, 500, 1000],
      defaultPresets: QuickAddConfiguration.defaultCaloriePresets
    ) { _ in } onCustom: {}
      .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .dark, accent: .calories))
  .preferredColorScheme(.dark)
}

#Preview("Light") {
  ZStack {
    CounterPageBackground()
    CompactQuickAddGrid(
      values: [10, 20, 50, 100, 200, 500, 1000],
      defaultPresets: QuickAddConfiguration.defaultCaloriePresets
    ) { _ in } onCustom: {}
      .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: .calories))
  .preferredColorScheme(.light)
}
