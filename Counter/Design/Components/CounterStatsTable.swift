import SwiftUI

struct CounterStatRow: Identifiable, Equatable {
  let id: String
  let value: String
  let label: String
  var isEmphasized: Bool = false
}

struct CounterStatsTable: View {
  @Environment(\.semanticColors) private var colors

  let rows: [CounterStatRow]

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
        if index > 0 {
          Rectangle()
            .fill(colors.textPrimary)
            .frame(height: index == rows.count - 1 ? BorderToken.statsRowStrong : BorderToken.statsRow)
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
      }
    }
  }
}
