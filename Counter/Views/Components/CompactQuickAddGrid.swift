import SwiftUI

struct CompactQuickAddGrid: View {
  let values: [Int]
  let onTap: (Int) -> Void
  let onCustom: () -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

  private var displayValues: [Int] {
    Array(values.prefix(8))
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(displayValues, id: \.self) { value in
        quickAddButton(label: "+\(value)") {
          onTap(value)
        }
      }

      quickAddButton(label: nil, systemImage: "ellipsis") {
        onCustom()
      }
    }
  }

  private func quickAddButton(
    label: String?,
    systemImage: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Group {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.body.weight(.semibold))
        } else {
          Text(label ?? "")
            .font(.subheadline.weight(.semibold).monospacedDigit())
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(.white.opacity(0.12), lineWidth: 1)
      )
      .foregroundStyle(.white)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  ZStack {
    CounterPageBackground(palette: CounterTheme.calories)
    CompactQuickAddGrid(values: [10, 20, 50, 100, 200, 500]) { _ in } onCustom: {}
      .padding()
  }
}
