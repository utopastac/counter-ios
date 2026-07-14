import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  var lineWidth: CGFloat = SizeToken.Ring.progressStroke
  var trackColor: Color?
  var fillColor: Color?

  private var fillFraction: Double {
    progress.isOverGoal ? 1 : progress.ringFraction
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
        overfillOverflowArc
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

  private var overfillOverflowArc: some View {
    let outlineWidth = SizeToken.Ring.overfillOutlineWidth
    let overflow = progress.overflowRingFraction
    let outlineStroke = StrokeStyle(
      lineWidth: lineWidth + outlineWidth * 2,
      lineCap: .round,
      lineJoin: .round
    )

    return ZStack {
      ProgressRingArc(fraction: overflow, lineWidth: lineWidth)
        .stroke(colors.progressRingOverfillOutline, style: outlineStroke)
        .mask {
          ProgressRingBandMask(lineWidth: lineWidth)
        }

      ProgressRingArc(fraction: overflow, lineWidth: lineWidth)
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

/// Arc segment for a progress ring, starting at 12 o'clock.
private struct ProgressRingArc: Shape {
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

/// Annulus mask that clips strokes to the progress ring band.
struct ProgressRingBandMask: View {
  let lineWidth: CGFloat

  var body: some View {
    ProgressRingBandShape(lineWidth: lineWidth)
      .fill(.white, style: FillStyle(eoFill: true))
  }
}

private struct ProgressRingBandShape: Shape {
  let lineWidth: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path(ellipseIn: rect)
    path.addPath(Path(ellipseIn: rect.insetBy(dx: lineWidth, dy: lineWidth)))
    return path
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
    }
    .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: .calories))
  .preferredColorScheme(.light)
}
