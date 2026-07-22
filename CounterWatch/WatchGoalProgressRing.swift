import SwiftUI

struct WatchGoalProgressRing: View {
  let progress: GoalProgress
  let theme: WatchThemeColors
  var size: CGFloat = 28
  var lineWidth: CGFloat = 4
  var ringStyle: ProgressRingStyle = AppAppearancePreference.progressRingStyle
  var ringGlowEnabled: Bool = AppAppearancePreference.isProgressRingGlowEnabled

  private var ringSides: Int? {
    ringStyle.ringSides
  }

  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ringLayer(fraction: 1, color: theme.ringTrack)

      if ringGlowEnabled {
        ringLayer(fraction: 1, color: Color.white.opacity(0.55))
          .blur(radius: lineWidth * 0.35)
          .mask { ringLayer(fraction: 1, color: .white) }
          .blendMode(.plusLighter)
      }

      if fillFraction > 0 {
        ringLayer(fraction: fillFraction, color: theme.foreground)
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  private var ringStrokeStyle: StrokeStyle {
    ringStyle.strokeStyle(lineWidth: lineWidth)
  }

  private func ringShape(fraction: Double) -> ProgressRingArc {
    ProgressRingArc(fraction: fraction, lineWidth: lineWidth, sides: ringSides)
  }

  @ViewBuilder
  private func ringLayer(fraction: Double, color: Color) -> some View {
    let shape = ringShape(fraction: fraction)
    if shape.usesFill {
      shape.fill(color)
    } else {
      shape.stroke(color, style: ringStrokeStyle)
    }
  }
}
