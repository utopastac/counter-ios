import SwiftUI
import SwiftData

struct CustomCounterPageContent: View {
  @Bindable var counter: CustomCounter
  @Environment(\.modelContext) private var modelContext

  @State private var showCustomAmount = false

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

  private var palette: CounterTheme.Palette {
    CounterTheme.forCounter(named: counter.name)
  }

  var body: some View {
    CounterPageLayout(
      title: counter.name,
      heroValue: heroValue,
      heroCaption: heroCaption,
      compactStat: CounterPeriodCalculator.resetSummary(for: counter),
      goalProgress: goalProgress,
      palette: palette
    ) {
      CompactQuickAddGrid(values: counter.buttonValues) { value in
        addEntryQuick(value)
      } onCustom: {
        showCustomAmount = true
      }
    }
    .sheet(isPresented: $showCustomAmount) {
      CustomAmountSheet { value in
        addEntry(value)
      }
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
