import SwiftUI

/// Arc segment for a progress ring, starting at 12 o'clock and sweeping clockwise.
///
/// Shared by the app's `GoalProgressRing` (`Counter/Views/Components/GoalProgressView.swift`)
/// and the home-screen widget's `WidgetProgressRing` (`CounterWidgets/WidgetTheme.swift`) so
/// the two rings stay pixel-identical instead of maintaining two copies of the same geometry.
struct ProgressRingArc: Shape {
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
