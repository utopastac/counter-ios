import SwiftUI
import Charts

struct HistoryChartView: View {
  let data: [DailyValue]
  let unit: String
  let period: HistoryPeriod

  var body: some View {
    if data.isEmpty {
      ContentUnavailableView("No Data", systemImage: "chart.bar", description: Text("Nothing recorded for this period."))
        .frame(height: 200)
    } else {
      Chart(data) { item in
        BarMark(
          x: .value("Date", item.date, unit: xAxisUnit),
          y: .value("Value", item.value)
        )
        .foregroundStyle(Color.accentColor.gradient)
      }
      .chartXAxis {
        AxisMarks(values: .automatic) { value in
          if let date = value.as(Date.self) {
            AxisValueLabel(format: xLabelFormat(for: date))
          }
        }
      }
      .frame(height: 220)
    }
  }

  private var xAxisUnit: Calendar.Component {
    switch period {
    case .daily, .monthly: .day
    case .weekly: .weekOfYear
    }
  }

  private func xLabelFormat(for date: Date) -> Date.FormatStyle {
    switch period {
    case .daily, .monthly:
      return .dateTime.month(.abbreviated).day()
    case .weekly:
      return .dateTime.month(.abbreviated).day()
    }
  }
}

#Preview {
  HistoryChartView(
    data: [
      DailyValue(date: .now, value: 120),
      DailyValue(date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, value: 80)
    ],
    unit: "kcal",
    period: .daily
  )
  .padding()
}
