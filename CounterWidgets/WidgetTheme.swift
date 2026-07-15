import SwiftUI

enum WidgetTheme {
  static let buttonHeight: CGFloat = 34
  static let buttonSpacing: CGFloat = 8
  static let buttonCornerRadius: CGFloat = 8
}

struct WidgetProgressRing: View {
  let fraction: Double
  let foreground: Color
  var size: CGFloat = 52
  var lineWidth: CGFloat = 12

  var body: some View {
    ZStack {
      if fraction > 0 {
        ProgressRingArc(fraction: min(fraction, 1), lineWidth: lineWidth)
          .stroke(foreground, style: ringStrokeStyle)
      }
    }
    .frame(width: size, height: size)
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }
}

struct WidgetQuickAddButton: View {
  let counter: CounterWidgetEntity
  let value: Int
  let colors: WidgetThemeColors

  var body: some View {
    Button(intent: AddCounterEntryIntent(counterID: counter.id, amount: value)) {
      Text("\(value)")
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(colors.buttonText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          colors.buttonFill,
          in: RoundedRectangle(cornerRadius: WidgetTheme.buttonCornerRadius, style: .continuous)
        )
    }
    .buttonStyle(.plain)
  }
}
