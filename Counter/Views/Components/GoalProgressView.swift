import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  var lineWidth: CGFloat = SizeToken.Ring.progressStroke
  var trackColor: Color?
  var fillColor: Color?

  /// The primary 0...1 lap. Snaps to the full ring once progress goes past 100% (the overflow
  /// arc then wraps on top of it) and drops to empty once progress goes below 0% (the
  /// underflow arc then winds backward from that empty ring instead).
  private var fillFraction: Double {
    if progress.isUnderZero { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ProgressRingArc(fraction: 1, lineWidth: lineWidth)
        .stroke(resolvedTrackColor, style: ringStrokeStyle)

      if fillFraction > 0 {
        ProgressRingArc(fraction: fillFraction, lineWidth: lineWidth)
          .stroke(resolvedFillColor, style: ringStrokeStyle)
      }

      if progress.underflowRingFraction > 0 {
        ProgressRingArc(fraction: progress.underflowRingFraction, lineWidth: lineWidth, clockwise: false)
          .stroke(resolvedFillColor, style: ringStrokeStyle)
      }

      if progress.overflowRingFraction > 0 {
        loopOverlapArc(fraction: progress.overflowRingFraction, clockwise: true)
      }

      if progress.underflowOverlapFraction > 0 {
        loopOverlapArc(fraction: progress.underflowOverlapFraction, clockwise: false)
      }
    }
    .animation(MotionToken.ringProgress(reduceMotion: reduceMotion), value: progress.current)
    .frame(width: size, height: size)
    .accessibilityLabel(progress.progressLabel)
    .accessibilityValue(progress.detailLabel)
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }

  /// Draws one wound-again lap on top of the completed base ring — an Apple Watch–style
  /// "activity ring" overlap. A wider outline stroke sits underneath the normal-width fill,
  /// so it peeks out as a visible rim/halo around the overlap's rounded caps (most noticeably
  /// at the growing tip) without needing to be masked to the ring band.
  private func loopOverlapArc(fraction: Double, clockwise: Bool) -> some View {
    let outlineWidth = SizeToken.Ring.overfillOutlineWidth
    let outlineStroke = StrokeStyle(
      lineWidth: lineWidth + outlineWidth * 2,
      lineCap: .round,
      lineJoin: .round
    )

    return ZStack {
      ProgressRingArc(fraction: fraction, lineWidth: lineWidth, clockwise: clockwise)
        .stroke(colors.progressRingOverfillOutline, style: outlineStroke)

      ProgressRingArc(fraction: fraction, lineWidth: lineWidth, clockwise: clockwise)
        .stroke(resolvedFillColor, style: ringStrokeStyle)
    }
  }

  private var resolvedTrackColor: Color {
    trackColor ?? colors.progressRingTrack
  }

  private var resolvedFillColor: Color {
    fillColor ?? colors.progressRingFill
  }
}

struct GoalProgressView: View {
  let progress: GoalProgress

  var body: some View {
    GlassCard {
      HStack(spacing: SpaceToken.x4) {
        GoalProgressRing(progress: progress)

        VStack(alignment: .leading, spacing: 6) {
          Text(progress.progressLabel)
            .counterTextStyle(.bodySecondary, color: .tertiary)

          Text(progress.detailLabel)
            .counterTextStyle(.numericLarge)
        }

        Spacer(minLength: 0)
      }
    }
  }
}

#Preview {
  ZStack {
    CounterPagerBackdrop(accents: [.calories], scrollProgress: 0)
    VStack(spacing: SpaceToken.x4) {
      GoalProgressView(
        progress: GoalProgress(current: 500, goal: 2000, direction: .countDown)
      )
      GoalProgressView(
        progress: GoalProgress(current: 1800, goal: 2000, direction: .countDown)
      )
      GoalProgressView(
        progress: GoalProgress(current: 2150, goal: 2000, direction: .countDown)
      )
      GoalProgressView(
        progress: GoalProgress(current: 3200, goal: 2000, direction: .countDown)
      )
      GoalProgressView(
        progress: GoalProgress(current: 6800, goal: 2000, direction: .countUp)
      )
      GoalProgressView(
        progress: GoalProgress(current: -900, goal: 2000, direction: .countUp)
      )
    }
    .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: .calories))
  .preferredColorScheme(.light)
}
