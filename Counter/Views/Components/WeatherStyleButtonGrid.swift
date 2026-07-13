import SwiftUI

struct WeatherStyleButtonGrid: View {
  let values: [Int]
  let onTap: (Int) -> Void

  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Quick Add")
        .font(.caption.weight(.semibold))
        .tracking(1.1)
        .foregroundStyle(.white.opacity(0.55))

      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(values, id: \.self) { value in
          Button {
            onTap(value)
          } label: {
            Text("+\(value)")
              .font(.title3.weight(.semibold).monospacedDigit())
              .frame(maxWidth: .infinity)
              .padding(.vertical, 18)
              .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .strokeBorder(.white.opacity(0.12), lineWidth: 1)
              )
              .foregroundStyle(.white)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

#Preview {
  ZStack {
    CounterPageBackground(palette: CounterTheme.calories)
    WeatherStyleButtonGrid(values: [10, 20, 50, 100, 200, 500]) { _ in }
      .padding()
  }
}
