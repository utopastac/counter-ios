import SwiftUI

struct WatchQuickAddGrid: View {
  let values: [Int]
  let defaultPresets: [Int]
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible(), spacing: 4),
    GridItem(.flexible(), spacing: 4),
    GridItem(.flexible(), spacing: 4)
  ]

  private var displayValues: [Int] {
    QuickAddConfiguration.filledPresets(from: values, defaults: defaultPresets)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 4) {
      ForEach(Array(displayValues.enumerated()), id: \.offset) { _, value in
        Button {
          onTap(value)
        } label: {
          Text("\(value)")
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color(white: 0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  WatchQuickAddGrid(
    values: [5, 10, 25, 50, 100, 200, 500, 1000],
    defaultPresets: QuickAddConfiguration.defaultCaloriePresets
  ) { _ in }
  .padding()
  .background(Color.black)
}
