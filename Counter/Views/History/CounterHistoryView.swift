import SwiftUI

struct CounterHistoryView: View {
  let counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors
  @State private var period: HistoryPeriod = .daily

  private var chartData: [DailyValue] {
    HistoryAggregator.groupedCounterTotals(from: counter.entries, period: period)
  }

  private var listItems: [HistoryListItem] {
    chartData.reversed().map { item in
      HistoryListItem(date: item.date, value: Int(item.value))
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(
        title: "\(counter.name) history",
        onDone: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: HistoryToken.sectionSpacing) {
          HistoryPeriodPicker(selection: $period)

          HistoryBarChart(data: chartData, period: period)

          if !listItems.isEmpty {
            HistoryList(items: listItems)
          }
        }
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u1)
        .padding(.bottom, SpaceToken.u4)
      }
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromColorScheme()
    .counterSheetPresentation()
  }
}

#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Calories"))
}
