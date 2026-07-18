import SwiftUI

struct HistoryListItem: Identifiable, Equatable {
  let date: Date
  let value: Double

  var id: Date { date }
}

struct HistoryList: View {
  let items: [HistoryListItem]
  var dateFormat: Date.FormatStyle = Date.FormatStyle().month(.abbreviated).day(.twoDigits)
  var onSelect: ((HistoryListItem) -> Void)?

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        if index > 0 {
          SettingsDivider()
        }

        HistoryListRow(item: item, dateFormat: dateFormat, onSelect: onSelect)
      }
    }
  }
}

private struct HistoryListRow: View {
  let item: HistoryListItem
  let dateFormat: Date.FormatStyle
  let onSelect: ((HistoryListItem) -> Void)?

  var body: some View {
    Button {
      onSelect?(item)
    } label: {
      HStack(alignment: .center, spacing: SpaceToken.x3) {
        Text(CounterFormatting.amount(item.value))
          .counterTextStyle(.historyListValue)

        Spacer(minLength: 0)

        Text(item.date, format: dateFormat)
          .counterTextStyle(.historyListDate)
      }
      .frame(height: HistoryToken.listRowHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(onSelect == nil)
  }
}

#Preview {
  HistoryList(
    items: [
      HistoryListItem(date: .now, value: 10),
      HistoryListItem(date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, value: 24.5),
      HistoryListItem(date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, value: 8)
    ]
  )
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
