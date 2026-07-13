import SwiftUI

struct WatchQuickAddGrid: View {
  let values: [Int]
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  private var displayValues: [Int] {
    QuickAddConfiguration.normalizedPresets(values)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(displayValues, id: \.self) { value in
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
  WatchQuickAddGrid(values: [10, 20, 50, 100]) { _ in }
}
