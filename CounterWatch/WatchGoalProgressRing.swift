import SwiftUI

struct WatchGoalProgressRing: View {
  let progress: GoalProgress
  let theme: WatchThemeColors
  var size: CGFloat = 28
  var lineWidth: CGFloat = 4

  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ProgressRingArc(fraction: 1, lineWidth: lineWidth)
        .stroke(theme.ringTrack, style: ringStrokeStyle)

      if fillFraction > 0 {
        ProgressRingArc(fraction: fillFraction, lineWidth: lineWidth)
          .stroke(theme.foreground, style: ringStrokeStyle)
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }
}
