import SwiftUI
import SwiftData

struct CaloriesPageContent: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var entries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  @State private var buttonValues: [Int] = AppSettings().calorieButtonValues
  @State private var showCustomAmount = false

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var periodTotal: Int {
    CounterPeriodCalculator.totalCalories(from: entries, for: settings)
  }

  private var goalProgress: GoalProgress? {
    GoalProgressCalculator.progress(
      current: periodTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
  }

  private var netCalories: Int {
    periodTotal - Int(healthKit.activeCalories)
  }

  var body: some View {
    CounterPageLayout(
      title: "Calories",
      heroValue: heroValue,
      heroCaption: heroCaption,
      compactStat: compactStat,
      goalProgress: goalProgress,
      palette: CounterTheme.calories
    ) {
      CompactQuickAddGrid(values: buttonValues) { value in
        addCaloriesQuick(value)
      } onCustom: {
        showCustomAmount = true
      }
    }
    .sheet(isPresented: $showCustomAmount) {
      CustomAmountSheet { value in
        addCalories(value)
      }
    }
    .onAppear {
      ensureSettings()
      syncWidgetSnapshot()
    }
    .onChange(of: settingsList.first?.calorieButtonValues) { _, newValues in
      if let newValues {
        buttonValues = newValues
      }
    }
    .onChange(of: periodTotal) { _, _ in syncWidgetSnapshot() }
    .onChange(of: healthKit.activeCalories) { _, _ in syncWidgetSnapshot() }
  }

  func refreshHealth() async {
    await healthKit.refreshToday()
    syncWidgetSnapshot()
  }

  private var heroValue: String {
    goalProgress?.heroValue ?? "\(periodTotal)"
  }

  private var heroCaption: String {
    goalProgress?.heroCaption ?? settings.calorieResetPeriod.periodCaption
  }

  private var compactStat: String? {
    var parts = ["Net \(formattedNet(netCalories)) kcal", "Active burned \(Int(healthKit.activeCalories)) kcal"]
    if let weight = healthKit.weightKg {
      parts.append(String(format: "%.1f kg", weight))
    }
    return parts.joined(separator: " · ")
  }

  private func addCalories(_ value: Int) {
    EntryActions.addCalorie(value: value, in: modelContext)
    syncWidgetSnapshot()
  }

  private func addCaloriesQuick(_ value: Int) {
    EntryActions.addCalorieQuick(value: value, in: modelContext)
    syncWidgetSnapshot()
  }

  private func syncWidgetSnapshot() {
    WidgetSnapshot.publish(added: periodTotal, burned: Int(healthKit.activeCalories))
  }

  private func ensureSettings() {
    if let settings = settingsList.first {
      buttonValues = settings.calorieButtonValues
    } else {
      let created = AppSettings()
      modelContext.insert(created)
      buttonValues = created.calorieButtonValues
    }
  }

  private func formattedNet(_ value: Int) -> String {
    value >= 0 ? "+\(value)" : "\(value)"
  }
}
