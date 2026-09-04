import SwiftUI

struct HistoryListItem: Identifiable, Equatable {
  let date: Date
  let value: Double

  var id: Date { date }
}

/// Aggregated history rows (week / month) — tap opens the bucket detail sheet.
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

        CounterValueDateRow(
          valueText: CounterFormatting.amount(item.value),
          date: item.date,
          dateFormat: dateFormat,
          onTap: onSelect.map { handler in { handler(item) } }
        )
        .disabled(onSelect == nil)
      }
    }
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
