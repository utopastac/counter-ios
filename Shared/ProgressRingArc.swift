import SwiftUI

/// Arc segment for a progress ring, starting at 12 o'clock.
///
/// Shared by the app's `GoalProgressRing` (`Counter/Views/Components/GoalProgressView.swift`)
/// and the home-screen widget's `WidgetProgressRing` (`CounterWidgets/WidgetTheme.swift`) so
/// the two rings stay pixel-identical instead of maintaining two copies of the same geometry.
///
/// `clockwise` picks the sweep direction — `GoalProgressRing` uses this to draw "under 0%"
/// loops winding backward from 12 o'clock, mirroring the normal forward ("over 100%") loops.
struct ProgressRingArc: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var clockwise: Bool = true

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
    let direction: Double = clockwise ? 1 : -1
    let end = Angle.degrees(-90 + direction * (clamped * 360))

    // SwiftUI's `Path.addArc(clockwise:)` is expressed in the flipped (y-down) coordinate
    // space, so it reads as the *opposite* of on-screen direction — negate our own
    // `clockwise` to keep the two arc directions visually correct.
    if clamped >= 0.999 {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: .degrees(-90 + direction * (360 - 0.001)),
        clockwise: !clockwise
      )
    } else {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: end,
        clockwise: !clockwise
      )
    }

    return path
  }
}
