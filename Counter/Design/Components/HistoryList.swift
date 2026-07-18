import SwiftUI

struct HistoryListItem: Identifiable, Equatable {
  let date: Date
  let value: Int

  var id: Date { date }
}

struct HistoryList: View {
  let items: [HistoryListItem]

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        if index > 0 {
          SettingsDivider()
        }

        HistoryListRow(item: item)
      }
    }
  }
}

private struct HistoryListRow: View {
  let item: HistoryListItem

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      Text(item.date, format: HistoryListRow.dateFormat)
        .counterTextStyle(.historyListDate)

      Spacer(minLength: 0)

      Text("\(item.value)")
        .counterTextStyle(.historyListValue)
    }
    .frame(height: HistoryToken.listRowHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private static let dateFormat = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
}

#Preview {
  HistoryList(
    items: [
      HistoryListItem(date: .now, value: 10),
      HistoryListItem(date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, value: 24),
      HistoryListItem(date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, value: 8)
    ]
  )
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
