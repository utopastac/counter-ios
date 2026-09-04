import SwiftUI

struct CounterStatRow: Identifiable, Equatable {
  let id: String
  let value: String
  let label: String
  var isEmphasized: Bool = false
}

struct CounterStatsTable: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let rows: [CounterStatRow]
  /// When `false`, rows rest collapsed (offset + hidden) for the header toggle transition.
  var isRevealed: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
        if index > 0 {
          Rectangle()
            .fill(colors.textPrimary)
            .frame(height: index == rows.count - 1 ? BorderToken.statsRowStrong : BorderToken.statsRow)
            .opacity(isRevealed ? 1 : 0)
            .animation(
              MotionToken.headerToggleRow(
                reduceMotion: reduceMotion,
                index: index,
                revealing: isRevealed
              ),
              value: isRevealed
            )
        }

        HStack(alignment: .center, spacing: 0) {
          Text(row.label)
            .counterTextStyle(.rowLight, color: .secondary)
            .fontWeight(index == rows.count - 1 ? .semibold : .regular)

          Spacer(minLength: SpaceToken.x3)

          Text(row.value)
            .counterTextStyle(.rowHeavy)
            .fontWeight(row.isEmphasized ? .bold : .semibold)
        }
        .frame(height: SizeToken.tableRowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isRevealed ? 1 : 0)
        .offset(y: rowOffset(for: index))
        .animation(
          MotionToken.headerToggleRow(
            reduceMotion: reduceMotion,
            index: index,
            revealing: isRevealed
          ),
          value: isRevealed
        )
      }
    }
  }

  private func rowOffset(for index: Int) -> CGFloat {
    guard !reduceMotion, !isRevealed else { return 0 }
    // Later rows start farther down so the stagger reads as a cascade, not a rigid slide.
    return CounterPageToken.headerStatsRevealOffset + CGFloat(index) * 2
  }
}
