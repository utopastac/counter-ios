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

  private var ringProgress: GoalProgress {
    GoalProgressCalculator.ringDisplay(
      current: periodTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
  }

  private var previewItems: [EntryLogPreviewItem] {
    periodEntries.prefix(EntryLogPreviewLimit.count).map { entry in
      EntryLogPreviewItem(
        id: entry.id,
        timestamp: entry.timestamp,
        valueText: "\(entry.value)"
      )
    }
  }

  private var statRows: [CounterStatRow] {
    var rows: [CounterStatRow] = []

    if let goal = settings.effectiveCalorieGoal {
      rows.append(CounterStatRow(id: "target", value: "\(goal)", label: "Target"))
    }

    rows.append(CounterStatRow(id: "added", value: "\(periodTotal)", label: "Added"))
    rows.append(
      CounterStatRow(
        id: "active",
        value: signedValue(Int(healthKit.activeCalories.rounded())),
        label: "Active"
      )
    )

    if let goalProgress = GoalProgressCalculator.progress(
      current: periodTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    ) {
      rows.append(
        CounterStatRow(
          id: "summary",
          value: goalProgress.heroValue,
          label: goalProgress.heroCaption.capitalized,
          isEmphasized: true
        )
      )
    }

    return rows
  }

  var body: some View {
    NavigationStack {
      CounterPageLayout(
        heroValue: heroValue,
        statRows: statRows,
        ringProgress: ringProgress
      ) {
        VStack(alignment: .leading, spacing: 0) {
          EntryLogHeroLink(
            isExpanded: $showsEntryLog,
            heroID: entryLogHeroID
          ) {
            EntryLogAllEntriesControl()
          } destination: {
            CaloriePeriodEntryLogScreen()
          }

          CompactEntryLogPreview(
            items: previewItems,
            emptyMessage: "No entries yet for this period."
          )
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
    .toolbarBackground(.hidden, for: .navigationBar)
    .background(Color.clear)
    .containerBackground(.clear, for: .navigation)
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

  private var heroValue: String {
    GoalProgressCalculator.progress(
      current: periodTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )?.heroValue ?? "\(periodTotal)"
  }

  private func signedValue(_ value: Int) -> String {
    value >= 0 ? "+\(value)" : "\(value)"
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
    WidgetSnapshotSync.publish(from: modelContext, burned: Int(healthKit.activeCalories))
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
}
