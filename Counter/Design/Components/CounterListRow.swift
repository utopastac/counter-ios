import SwiftUI

struct CounterListRow: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  let total: Int
  let progress: GoalProgress?
  let periodCaption: String
  let suffix: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: SpaceToken.x3 + 2) {
        if let progress {
          GoalProgressRing(progress: progress, size: SizeToken.Ring.list, lineWidth: SizeToken.Ring.listStroke)
        } else {
          noGoalBadge
        }

        VStack(alignment: .leading, spacing: SpaceToken.x1) {
          Text(title)
            .counterTextStyle(.headline, color: .primary)

          if let progress {
            Text(progress.listSubtitle + (suffix.map { " \($0)" } ?? ""))
              .counterTextStyle(.caption, color: .secondary)
          } else {
            Text(formattedTotal(total, suffix: suffix) + " · \(periodCaption)")
              .counterTextStyle(.caption, color: .secondary)
          }
        }

        Spacer(minLength: 0)

        if let progress {
          VStack(alignment: .trailing, spacing: 2) {
            Text(progress.summaryValue + (suffix.map { " \($0)" } ?? ""))
              .counterTextStyle(.subheadlineSemibold, color: .primary)
            Text(progress.summaryCaption)
              .counterTextStyle(.caption2, color: .secondary)
          }
        }
      }
      .padding(.vertical, SpaceToken.x1)
    }
    .buttonStyle(.plain)
  }

  private var noGoalBadge: some View {
    ZStack {
      Circle()
        .stroke(colors.progressRingTrack, lineWidth: SizeToken.Ring.listStroke)
      Text(formattedTotal(total, suffix: suffix))
        .counterTextStyle(.caption, color: .primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(SpaceToken.x2)
    }
    .frame(width: SizeToken.Ring.list, height: SizeToken.Ring.list)
  }

  private func formattedTotal(_ total: Int, suffix: String?) -> String {
    if let suffix {
      return "\(total) \(suffix)"
    }
    return "\(total)"
  }
}
