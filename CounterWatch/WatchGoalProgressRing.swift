import SwiftUI

struct WatchGoalProgressRing: View {
  let progress: GoalProgress
  let theme: WatchThemeColors
  var size: CGFloat = 28
  var lineWidth: CGFloat = 4
  var ringGlowEnabled: Bool = AppAppearancePreference.isProgressRingGlowEnabled

  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ringLayer(fraction: 1, color: theme.ringTrack)
        .blur(radius: ringGlowEnabled ? ProgressRingGlowMetrics.trackBlurRadius : 0)

      if ringGlowEnabled {
        ringLayer(fraction: 1, color: Color.white.opacity(ProgressRingGlowMetrics.highlightOpacity))
          .blur(radius: lineWidth * ProgressRingGlowMetrics.highlightBlurFactor)
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

  private func ringLayer(fraction: Double, color: Color) -> some View {
    ProgressRingArc(fraction: fraction, lineWidth: lineWidth)
      .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
  }
}
