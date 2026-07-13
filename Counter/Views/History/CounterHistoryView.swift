import SwiftUI

struct CounterHistoryView: View {
  let counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @State private var period: HistoryPeriod = .daily

  private var chartData: [DailyValue] {
    HistoryAggregator.groupedCounterTotals(from: counter.entries, period: period)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          PeriodPicker(selection: $period)

          VStack(alignment: .leading, spacing: 8) {
            Text(counter.name)
              .font(.headline)
            HistoryChartView(data: chartData, unit: counter.name, period: period)
          }

          if !chartData.isEmpty {
            List {
              ForEach(chartData.reversed()) { item in
                HStack {
                  Text(item.date, format: .dateTime.weekday(.abbreviated).month().day())
                  Spacer()
                  Text("\(Int(item.value))")
                    .fontWeight(.semibold)
                }
              }
            }
            .frame(minHeight: 200)
          }
        }
        .padding()
      }
      .navigationTitle("\(counter.name) History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Protein"))
}
