import SwiftUI
import SwiftData

struct WatchCalorieView: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var entries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  @State private var buttonValues: [Int] = AppSettings().calorieButtonValues

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var periodTotal: Int {
    CounterPeriodCalculator.totalCalories(from: entries, for: settings)
  }

  private var netCalories: Double {
    Double(periodTotal) - healthKit.activeCalories
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          summaryRow(label: "Active burned", value: Int(healthKit.activeCalories))
          summaryRow(label: "Added", value: periodTotal)
          summaryRow(label: "Net", value: Int(netCalories), highlight: true)

          Divider()

          WatchQuickAddGrid(values: buttonValues) { value in
            addCaloriesQuick(value)
          }
        }
        .padding(.horizontal, 4)
      }
      .navigationTitle("Calories")
    }
    .onAppear {
      loadSettings()
      syncWidgetSnapshot()
    }
    .onChange(of: settingsList.first?.calorieButtonValues) { _, newValues in
      if let newValues {
        buttonValues = newValues
      }
    }
    .onChange(of: periodTotal) { _, _ in
      syncWidgetSnapshot()
    }
    .onChange(of: healthKit.activeCalories) { _, _ in
      syncWidgetSnapshot()
    }
  }

  private func summaryRow(label: String, value: Int, highlight: Bool = false) -> some View {
    HStack {
      Text(label)
        .foregroundStyle(.secondary)
      Spacer()
      Text("\(value)")
        .font(highlight ? .headline : .body)
        .foregroundStyle(highlight ? (value > 0 ? .red : .green) : .primary)
    }
  }

  private func addCaloriesQuick(_ value: Int) {
    EntryActions.addCalorieQuick(value: value, in: modelContext)
    syncWidgetSnapshot()
  }

  private func loadSettings() {
    if let settings = settingsList.first {
      buttonValues = settings.calorieButtonValues
    }
  }

  private func syncWidgetSnapshot() {
    WidgetSnapshot.publish(
      added: periodTotal,
      burned: Int(healthKit.activeCalories)
    )
  }
}

#Preview {
  WatchCalorieView()
    .environment(HealthKitManager())
    .modelContainer(for: [CalorieEntry.self, AppSettings.self], inMemory: true)
}
