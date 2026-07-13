import SwiftUI
import SwiftData

struct CaloriesPageContent: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var entries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  @State private var buttonValues: [Int] = AppSettings().calorieButtonValues
  @State private var showCustomAmount = false
  @State private var showsEntryLog = false

  private let entryLogHeroID = "entry-log-calories"

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var periodEntries: [CalorieEntry] {
    let range = CounterPeriodCalculator.currentRange(for: settings)
    return CounterPeriodCalculator.calorieEntries(from: entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
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

  private var previewItems: [EntryLogPreviewItem] {
    periodEntries.prefix(8).map { entry in
      EntryLogPreviewItem(
        id: entry.id,
        timestamp: entry.timestamp,
        valueText: "\(entry.value) kcal"
      )
    }
  }

  var body: some View {
    NavigationStack {
      CounterPageLayout(
        title: "Calories",
        heroValue: heroValue,
        heroCaption: heroCaption,
        compactStat: compactStat,
        goalProgress: goalProgress
      ) {
        EntryLogHeroLink(
          isExpanded: $showsEntryLog,
          heroID: entryLogHeroID
        ) {
          CompactEntryLogPreview(
            title: EntryLogTitles.preview(for: settings.calorieResetPeriod),
            items: previewItems,
            emptyMessage: "No entries yet for this period."
          )
        } destination: {
          CaloriePeriodEntryLogScreen()
        }
      } footer: {
        CompactQuickAddGrid(
          values: buttonValues,
          defaultPresets: QuickAddConfiguration.defaultCaloriePresets
        ) { value in
          addCaloriesQuick(value)
        } onCustom: {
          showCustomAmount = true
        }
      }
    }
    .counterAccent(CounterAccent.calories)
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
      if let newValues, let settings = settingsList.first {
        migratePresetButtons(for: settings)
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
      migratePresetButtons(for: settings)
    } else {
      let created = AppSettings()
      modelContext.insert(created)
      buttonValues = created.calorieButtonValues
    }
  }

  private func migratePresetButtons(for settings: AppSettings) {
    let filled = QuickAddConfiguration.filledPresets(
      from: settings.calorieButtonValues,
      defaults: QuickAddConfiguration.defaultCaloriePresets
    )
    if filled != settings.calorieButtonValues {
      settings.calorieButtonValues = filled
    }
    buttonValues = filled
  }

  private func formattedNet(_ value: Int) -> String {
    value >= 0 ? "+\(value)" : "\(value)"
  }
}
