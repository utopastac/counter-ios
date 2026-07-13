import SwiftUI
import SwiftData

struct CustomCounterPageContent: View {
  @Bindable var counter: CustomCounter
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

  private var goalProgress: GoalProgress? {
    GoalProgressCalculator.progress(
      current: periodTotal,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )
  }

  private var previewItems: [EntryLogPreviewItem] {
    periodEntries.prefix(8).map { entry in
      EntryLogPreviewItem(
        id: entry.id,
        timestamp: entry.timestamp,
        valueText: "\(entry.value)"
      )
    }
  }

  var body: some View {
    NavigationStack {
      CounterPageLayout(
        title: counter.name,
        heroValue: heroValue,
        heroCaption: heroCaption,
        compactStat: CounterPeriodCalculator.resetSummary(for: counter),
        goalProgress: goalProgress
      ) {
        EntryLogHeroLink(
          isExpanded: $showsEntryLog,
          heroID: entryLogHeroID
        ) {
          CompactEntryLogPreview(
            title: EntryLogTitles.preview(for: counter.resetPeriod),
            items: previewItems,
            emptyMessage: "No entries yet for this period."
          )
        } destination: {
          CounterPeriodEntryLogScreen(counter: counter)
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
    .counterAccent(CounterAccent.forCounter(named: counter.name))
    .sheet(isPresented: $showCustomAmount) {
      CustomAmountSheet { value in
        addEntry(value)
      }
    }
    .onAppear {
      migratePresetButtons(for: counter)
    }
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

  private var heroValue: String {
    goalProgress?.heroValue ?? "\(periodTotal)"
  }

  private var heroCaption: String {
    goalProgress?.heroCaption ?? counter.resetPeriod.periodCaption
  }

  private func addEntry(_ value: Int) {
    EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
  }

  private func addEntryQuick(_ value: Int) {
    EntryActions.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
  }
}
