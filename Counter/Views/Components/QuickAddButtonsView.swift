import SwiftUI

struct QuickAddButtonsView: View {
  let values: [Int]
  let unit: String
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(values, id: \.self) { value in
        Button {
          onTap(value)
        } label: {
          Text("+\(value)")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview("Interactive") {
  PreviewModel.appRoot {
    CalorieCounterView()
  }
}

#Preview("Buttons only") {
  @Previewable @State var total = 0

  return QuickAddButtonsView(values: [10, 20, 50, 100], unit: "kcal") { value in
    total += value
  }
  .padding()
  .overlay(alignment: .bottom) {
    Text("Logged: \(total) kcal")
      .font(.caption)
      .padding()
  }
}
