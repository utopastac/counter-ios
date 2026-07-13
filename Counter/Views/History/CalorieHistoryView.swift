import SwiftUI
import SwiftData

struct CalorieHistoryView: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \CalorieEntry.timestamp) private var entries: [CalorieEntry]

  @State private var period: HistoryPeriod = .daily
  @State private var consumedData: [DailyValue] = []
  @State private var activeData: [DailyValue] = []

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          PeriodPicker(selection: $period)

          historySection(title: "Calories Added", data: consumedData, color: .green)
          historySection(title: "Active Burned", data: activeData, color: .orange)

          netHistorySection
        }
        .padding()
      }
      .navigationTitle("Calorie History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .task(id: period) {
        await loadHistory()
      }
    }
  }

  private func historySection(title: String, data: [DailyValue], color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
      HistoryChartView(data: data, unit: "kcal", period: period)
    }
  }

  private var netHistorySection: some View {
    let netData = zip(consumedData, activeData).map { consumed, burned in
      DailyValue(date: consumed.date, value: consumed.value - burned.value)
    }

    return VStack(alignment: .leading, spacing: 8) {
      Text("Net (Added − Active Burned)")
        .font(.headline)
      HistoryChartView(data: netData, unit: "kcal", period: period)
    }
  }

  private func loadHistory() async {
    consumedData = HistoryAggregator.groupedConsumedCalories(from: entries, period: period)
    activeData = await healthKit.fetchEnergyHistory(for: .activeEnergyBurned, period: period)
  }
}

#Preview {
  CalorieHistoryView()
    .environment(HealthKitManager())
    .modelContainer(for: CalorieEntry.self, inMemory: true)
}
