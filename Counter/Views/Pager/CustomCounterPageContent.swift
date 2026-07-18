import SwiftUI
import SwiftData

struct CustomCounterPageContent: View {
  @Bindable var counter: CustomCounter

  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
  @Environment(CounterSheetCoordinator.self) private var sheets
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(AppAppearancePreference.hapticsEnabledKey) private var isHapticsEnabled = true

  var isCompact = false
  var onShowHistory: () -> Void = {}
  var onShowButtonSettings: () -> Void = {}

  @State private var entryToast: EntryToastState?
  @State private var quickAddStore = QuickAddSessionStore()
  @State private var impactHapticTrigger = 0
  @State private var undoHapticTrigger = 0

  private var pageAccent: CounterAccent {
    let _ = (isMonoEnabled, monoPaletteIndex)
    return CounterAccent.forCounter(counter)
  }

  private var periodEntries: [CounterEntry] {
    CounterPeriodCalculator.currentEntries(for: counter)
  }

  private var periodTotal: Int {
    counter.currentTotal()
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
    Group {
      if isCompact {
        CompactCounterCardLayout(
          title: counter.name,
          heroValue: heroValue,
          heroSubtitle: heroSubtitle,
          ringProgress: counter.currentProgress(),
          onSelectEntryLog: { sheets.present(.entryLog(counterID: counter.id)) },
          onShowHistory: onShowHistory,
          onShowButtonSettings: onShowButtonSettings
        ) {
          CompactQuickAddGrid(
            values: counter.buttonValues,
            defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name),
            buttonHeight: CompactCardToken.quickAddHeight
          ) { value in
            addEntryQuick(value)
          } onCustom: {
            sheets.present(.customAmount(counterID: counter.id))
          }
        } toast: {
          if let entryToast {
            EntryAddedToast(value: entryToast.value) {
              undoToastEntry(entryToast.entryID)
            }
            .transition(toastTransition)
          }
        }
      } else {
        CounterPageLayout(
            heroValue: heroValue,
            heroSubtitle: heroSubtitle,
            statRows: statRows,
            ringProgress: counter.currentProgress()
          ) {
            VStack(alignment: .leading, spacing: 0) {
              Button {
                guard !counterRevealIsDragging else { return }
                sheets.present(.entryLog(counterID: counter.id))
              } label: {
                VStack(alignment: .leading, spacing: 0) {
                  CompactEntryLogPreview(items: previewItems)

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
              defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
            ) { value in
              addEntryQuick(value)
            } onCustom: {
              sheets.present(.customAmount(counterID: counter.id))
            }
          } toast: {
            if let entryToast {
              EntryAddedToast(value: entryToast.value) {
                undoToastEntry(entryToast.entryID)
              }
              .transition(toastTransition)
            }
          }
      }
    }
    .counterAccent(pageAccent)
    .sensoryFeedback(.impact(weight: .light), trigger: impactHapticTrigger) { _, _ in
      isHapticsEnabled
    }
    .sensoryFeedback(.warning, trigger: undoHapticTrigger) { _, _ in
      isHapticsEnabled
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
      defaults: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    )
    if filled != counter.buttonValues {
      counter.buttonValues = filled
    }
  }

  private func addEntry(_ value: Int) {
    let added = EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
    impactHapticTrigger &+= 1
    presentToast(for: added)
    syncWidgets()
  }

  private func addEntryQuick(_ value: Int) {
    let added = quickAddStore.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
    impactHapticTrigger &+= 1
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
    undoHapticTrigger &+= 1
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = nil
    }
    syncWidgets()
  }

  private func syncWidgets() {
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}
