import SwiftUI

struct GoalProgressRing: View {
  let progress: GoalProgress
  var size: CGFloat = 88
  var lineWidth: CGFloat = 10

  var body: some View {
    ZStack {
      Circle()
        .stroke(.white.opacity(0.14), lineWidth: lineWidth)

      Circle()
        .trim(from: 0, to: progress.ringFraction)
        .stroke(
          progress.isOverGoal ? Color.orange.opacity(0.95) : Color.white.opacity(0.9),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text("\(progress.percentComplete)%")
          .font(.system(size: ringFontSize, weight: .semibold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(.white)
          .minimumScaleFactor(0.7)
          .lineLimit(1)
      }
      .padding(lineWidth + 4)
    }
    .frame(width: size, height: size)
  }

  private var ringFontSize: CGFloat {
    size * 0.22
  }
}

struct GoalProgressView: View {
  let progress: GoalProgress

  var body: some View {
    HStack(spacing: 16) {
      GoalProgressRing(progress: progress)

      VStack(alignment: .leading, spacing: 6) {
        Text(progress.progressLabel)
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.75))

        Text(progress.detailLabel)
          .font(.title3.weight(.semibold).monospacedDigit())
          .foregroundStyle(.white)
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
    )
  }
}

#Preview {
  ZStack {
    CounterPageBackground(palette: CounterTheme.calories)
    VStack(spacing: 16) {
      GoalProgressView(
        progress: GoalProgress(current: 500, goal: 2000, direction: .countDown)
      )
      GoalProgressView(
        progress: GoalProgress(current: 2150, goal: 2000, direction: .countDown)
      )
    }
    .padding()
  }
}
