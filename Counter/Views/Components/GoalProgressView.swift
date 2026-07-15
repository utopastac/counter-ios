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
  /// arc then wraps on top of it) and drops to empty once progress goes below 0% — there's no
  /// backward/negative visualization, just an empty ring.
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

      if progress.overflowRingFraction > 0 {
        loopOverlapArc(fraction: progress.overflowRingFraction)
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
  /// "activity ring" overlap. A halo sits underneath *only* the growing tip end of the arc
  /// (not the fixed 12 o'clock start, which just resumes the previous lap), so the fill drawn
  /// on top leaves a visible rim around the tip's rounded cap without touching the start cap.
  private func loopOverlapArc(fraction: Double) -> some View {
    let outlineWidth = SizeToken.Ring.overfillOutlineWidth

    return ZStack {
      RingTipHalo(fraction: fraction, lineWidth: lineWidth, haloRadius: lineWidth / 2 + outlineWidth)
        .fill(colors.progressRingOverfillOutline)

      ProgressRingArc(fraction: fraction, lineWidth: lineWidth)
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

/// A small filled disc centered on the tip (leading end) of a `ProgressRingArc` with the same
/// `fraction`/`lineWidth` — used to draw the overlap "halo" at just the growing end of a loop,
/// without also touching its fixed start at 12 o'clock.
private struct RingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let clamped = max(min(fraction, 1), 0)
    guard clamped > 0 else { return Path() }

    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let sweepDegrees = clamped >= 0.999 ? 360 - 0.001 : clamped * 360
    let tipAngle = Angle.degrees(-90 + sweepDegrees)

    let tipPoint = CGPoint(
      x: center.x + radius * cos(tipAngle.radians),
      y: center.y + radius * sin(tipAngle.radians)
    )

    return Path(
      ellipseIn: CGRect(
        x: tipPoint.x - haloRadius,
        y: tipPoint.y - haloRadius,
        width: haloRadius * 2,
        height: haloRadius * 2
      )
    )
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
