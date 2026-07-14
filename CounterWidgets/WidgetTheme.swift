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
        WidgetRingArc(fraction: min(fraction, 1), lineWidth: lineWidth)
          .stroke(foreground, style: ringStrokeStyle)
      }
    }
    .frame(width: size, height: size)
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }
}

private struct WidgetRingArc: Shape {
  var fraction: Double
  var lineWidth: CGFloat

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let clamped = max(min(fraction, 1), 0)
    guard clamped > 0 else { return path }

    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let start = Angle.degrees(-90)
    let end = Angle.degrees(-90 + (clamped * 360))

    if clamped >= 0.999 {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: .degrees(270 - 0.001),
        clockwise: false
      )
    } else {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: end,
        clockwise: false
      )
    }

    return path
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
