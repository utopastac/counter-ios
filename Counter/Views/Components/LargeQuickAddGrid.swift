import SwiftUI

struct LargeQuickAddGrid: View {
  let values: [Int]
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.x3) {
      SectionLabel(title: "Quick Add")

      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(values, id: \.self) { value in
          GlassButton("\(value)") {
            onTap(value)
          }
        }
      }
    }
  }
}

#Preview {
  ZStack {
    CounterPagerBackdrop(accents: [.calories], scrollProgress: 0)
    LargeQuickAddGrid(values: [10, 20, 50, 100, 200, 500]) { _ in }
      .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .dark, accent: .calories))
}
