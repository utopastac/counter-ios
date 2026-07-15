import SwiftUI
import SwiftData

struct CustomCounterPageContent: View {
  @Bindable var counter: CustomCounter

  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  @State private var showCustomAmount = false
  @State private var showsEntryLog = false
  @State private var entryToast: EntryToastState?

  private var periodEntries: [CounterEntry] {
    let range = CounterPeriodCalculator.currentRange(for: counter)
    return CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
  }

  private var periodTotal: Int {
    counter.currentTotal()
  }

  private var ringProgress: GoalProgress {
    counter.currentRingDisplay()
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

    if let goalProgress = counter.currentProgress() {
      rows.append(
        CounterStatRow(
          id: "summary",
          value: goalProgress.statsSummaryValue,
          label: goalProgress.statsSummaryLabel,
          isEmphasized: true
        )
      )
    }

    return rows
  }

  var body: some View {
    CounterPageLayout(
        heroValue: heroValue,
        heroSubtitle: heroSubtitle,
        statRows: statRows,
        ringProgress: ringProgress
      ) {
        VStack(alignment: .leading, spacing: 0) {
          Button {
            guard !counterRevealIsDragging else { return }
            showsEntryLog = true
          } label: {
            VStack(alignment: .leading, spacing: 0) {
              CompactEntryLogPreview(
                items: previewItems,
                emptyMessage: "No entries yet for this period."
              )

              EntryLogAllEntriesControl()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.noHighlight)
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
      } toast: {
        if let entryToast {
          EntryAddedToast(value: entryToast.value) {
            undoToastEntry(entryToast.entryID)
          }
          .transition(toastTransition)
        }
      }
    .counterAccent(CounterAccent.forCounter(counter))
    .sheet(isPresented: $showCustomAmount) {
      CustomAmountSheet { value in
        addEntry(value)
      }
    }
    .sheet(isPresented: $showsEntryLog) {
      CounterTodayLogView(counter: counter)
    }
    .onAppear {
      migratePresetButtons(for: counter)
    }
    .onChange(of: periodTotal) { _, _ in
      syncWidgets()
    }
    .task(id: entryToast) {
      guard entryToast != nil else { return }
      try? await Task.sleep(for: .seconds(EntryActions.entryToastDuration))
      guard !Task.isCancelled else { return }
      withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
        entryToast = nil
      }
    }
  }

  private var toastTransition: AnyTransition {
    if reduceMotion {
      return .opacity
    }
    return .opacity.combined(with: .scale(scale: 0.96))
  }

  private var heroValue: String {
    counter.currentProgress()?.heroValue ?? "\(periodTotal)"
  }

  private var heroSubtitle: String? {
    counter.currentProgress()?.heroSubtitle
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
    let added = EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
    presentToast(for: added)
    syncWidgets()
  }

  private func addEntryQuick(_ value: Int) {
    let added = EntryActions.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
    presentToast(for: added)
    syncWidgets()
  }

  private func presentToast(for added: EntryActions.AddedEntry) {
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = EntryToastState(entryID: added.entryID, value: added.value)
    }
  }

  private func undoToastEntry(_ entryID: UUID) {
    EntryActions.deleteCounterEntry(id: entryID, in: modelContext)
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = nil
    }
    syncWidgets()
  }

  private func syncWidgets() {
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}
