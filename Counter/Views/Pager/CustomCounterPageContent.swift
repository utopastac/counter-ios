import SwiftUI
import SwiftData

struct CustomCounterPageContent: View {
  @Bindable var counter: CustomCounter
  let paletteIndex: Int

  @Environment(\.modelContext) private var modelContext

  @State private var showCustomAmount = false
  @State private var showsEntryLog = false

  private var entryLogHeroID: String {
    "entry-log-\(counter.id.uuidString)"
  }

  private var periodEntries: [CounterEntry] {
    let range = CounterPeriodCalculator.currentRange(for: counter)
    return CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
  }

  private var periodTotal: Int {
    CounterPeriodCalculator.total(from: counter.entries, for: counter)
  }

  private var ringProgress: GoalProgress {
    GoalProgressCalculator.ringDisplay(
      current: periodTotal,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
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

    if let goal = counter.effectiveGoal {
      rows.append(CounterStatRow(id: "target", value: "\(goal)", label: "Target"))
    }

    rows.append(CounterStatRow(id: "added", value: "\(periodTotal)", label: "Added"))

    if let goalProgress = GoalProgressCalculator.progress(
      current: periodTotal,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
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
            CounterPeriodEntryLogScreen(counter: counter)
          }

          CompactEntryLogPreview(
            items: previewItems,
            emptyMessage: "No entries yet for this period."
          )
        }
      } footer: {
        CompactQuickAddGrid(
          values: counter.buttonValues,
          defaultPresets: QuickAddConfiguration.defaultCounterPresets
        ) { value in
          addEntryQuick(value)
        } onCustom: {
          showCustomAmount = true
        }
      }
    }
    .counterAccent(CounterAccent.forCustomCounter(at: paletteIndex))
    .toolbarBackground(.hidden, for: .navigationBar)
    .background(Color.clear)
    .containerBackground(.clear, for: .navigation)
    .sheet(isPresented: $showCustomAmount) {
      CustomAmountSheet { value in
        addEntry(value)
      }
    }
    .onAppear {
      migratePresetButtons(for: counter)
    }
    .onChange(of: periodTotal) { _, _ in
      syncWidgets()
    }
  }

  private var heroValue: String {
    GoalProgressCalculator.progress(
      current: periodTotal,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )?.heroValue ?? "\(periodTotal)"
  }

  private func migratePresetButtons(for counter: CustomCounter) {
    let filled = QuickAddConfiguration.filledPresets(
      from: counter.buttonValues,
      defaults: QuickAddConfiguration.defaultCounterPresets
    )
    if filled != counter.buttonValues {
      counter.buttonValues = filled
    }
  }

  private func addEntry(_ value: Int) {
    EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
    syncWidgets()
  }

  private func addEntryQuick(_ value: Int) {
    EntryActions.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
    syncWidgets()
  }

  private func syncWidgets() {
    WidgetSnapshot.reloadTimelines()
  }
}
