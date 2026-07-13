import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  var lineWidth: CGFloat = SizeToken.Ring.progressStroke

  var body: some View {
    ZStack {
      Circle()
        .stroke(colors.progressRingTrack, lineWidth: lineWidth)

      if progress.isOverGoal {
        partialProgressRing(fraction: 1)

        if progress.overflowRingFraction > 0 {
          overfillOverflowArc
        }
      } else {
        partialProgressRing(fraction: progress.ringFraction)
      }
    }
    .frame(width: size, height: size)
  }

  private var overfillOverflowArc: some View {
    let outlineWidth = SizeToken.Ring.overfillOutlineWidth
    let overflow = progress.overflowRingFraction

    return ZStack {
      partialProgressRing(
        fraction: overflow,
        fill: colors.progressRingOverfillOutline,
        width: lineWidth + outlineWidth * 2
      )
      .mask {
        ProgressRingBandMask(lineWidth: lineWidth)
      }

      partialProgressRing(
        fraction: overflow,
        fill: colors.progressRingFill,
        width: lineWidth
      )
    }
  }

  private func partialProgressRing(
    fraction: Double,
    fill: Color? = nil,
    width: CGFloat? = nil
  ) -> some View {
    Circle()
      .trim(from: 0, to: fraction)
      .stroke(
        fill ?? colors.progressRingFill,
        style: StrokeStyle(lineWidth: width ?? lineWidth, lineCap: .round)
      )
      .rotationEffect(.degrees(-90))
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
    CounterPageBackground()
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
