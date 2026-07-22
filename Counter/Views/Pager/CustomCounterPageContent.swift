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
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(AppAppearancePreference.hapticsEnabledKey) private var isHapticsEnabled = true

  var isCompact = false
  var onShowHistory: () -> Void = {}
  var onShowButtonSettings: () -> Void = {}

  @State private var entryToast: EntryToastState?
  @State private var quickAddStore = QuickAddSessionStore()
  @State private var impactHapticTrigger = 0
  @State private var undoHapticTrigger = 0

  private var pageAccent: CounterAccent {
    let _ = (isMonoEnabled, monoPaletteIndex, isTintEnabled, colorPackRaw)
    return CounterAccent.forCounter(counter)
  }

  private var periodEntries: [CounterEntry] {
    CounterPeriodCalculator.currentEntries(for: counter)
  }

  private var periodTotal: Double {
    counter.currentTotal()
  }

  private var previewItems: [EntryLogPreviewItem] {
    periodEntries.prefix(EntryLogPreviewLimit.count).map { entry in
      EntryLogPreviewItem(
        id: entry.id,
        timestamp: entry.timestamp,
        valueText: CounterFormatting.amount(entry.amount)
      )
    }
  }

  private var statRows: [CounterStatRow] {
    var rows: [CounterStatRow] = []

    if let goal = counter.effectiveGoal {
      rows.append(
        CounterStatRow(
          id: "target",
          value: CounterFormatting.amount(goal),
          label: "Target"
        )
      )
    }

    rows.append(
      CounterStatRow(
        id: "added",
        value: CounterFormatting.amount(periodTotal),
        label: "Added"
      )
    )

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
          title: CounterFormatting.titleWithUnit(
            name: counter.name,
            unit: counter.effectiveUnit
          ),
          heroValue: heroValue,
          heroSubtitle: heroSubtitle,
          ringProgress: counter.currentProgress(),
          ringStyleOverride: counter.overrideProgressRingStyle,
          ringWidthOverride: counter.overrideProgressRingWidth,
          ringGlowOverride: counter.overrideProgressRingGlow,
          onSelectEntryLog: { sheets.present(.entryLog(counterID: counter.id)) },
          onShowHistory: onShowHistory,
          onShowButtonSettings: onShowButtonSettings
        ) {
          CompactQuickAddGrid(
            values: counter.presetAmounts,
            defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name),
            buttonHeight: CompactCardToken.quickAddHeight
          ) { value in
            addEntryQuick(value)
          } onCustom: {
            sheets.present(.customAmount(counterID: counter.id))
          }
        } toast: {
          if let entryToast {
            EntryAddedToast(value: entryToast.value, kind: entryToast.kind) {
              undoToast(entryToast)
            }
            .transition(toastTransition)
          }
        }
      } else {
        CounterPageLayout(
            heroValue: heroValue,
            heroSubtitle: heroSubtitle,
            statRows: statRows,
            ringProgress: counter.currentProgress(),
            ringStyleOverride: counter.overrideProgressRingStyle,
            ringWidthOverride: counter.overrideProgressRingWidth,
            ringGlowOverride: counter.overrideProgressRingGlow
          ) {
            VStack(alignment: .leading, spacing: 0) {
              CompactEntryLogPreview(items: previewItems) { entryID in
                deletePreviewEntry(id: entryID)
              }

              Button {
                guard !counterRevealIsDragging else { return }
                sheets.present(.entryLog(counterID: counter.id))
              } label: {
                EntryLogAllEntriesControl()
                  .frame(maxWidth: .infinity, alignment: .center)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.noHighlight)
            }
          } footer: {
            CompactQuickAddGrid(
              values: counter.presetAmounts,
              defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
            ) { value in
              addEntryQuick(value)
            } onCustom: {
              sheets.present(.customAmount(counterID: counter.id))
            }
          } toast: {
            if let entryToast {
              EntryAddedToast(value: entryToast.value, kind: entryToast.kind) {
                undoToast(entryToast)
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
    counter.currentProgress()?.heroValue
      ?? CounterFormatting.amount(periodTotal)
  }

  private var heroSubtitle: String? {
    counter.currentProgress()?.heroSubtitle
  }

  private func migratePresetButtons(for counter: CustomCounter) {
    let filled = QuickAddConfiguration.filledPresets(
      from: counter.presetAmounts,
      defaults: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    )
    if filled != counter.presetAmounts {
      counter.presetAmounts = filled
    }
  }

  private func addEntry(_ value: Double) {
    let added = EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
    impactHapticTrigger &+= 1
    AppSounds.log()
    presentToast(for: added)
    syncWidgets()
  }

  private func addEntryQuick(_ value: Double) {
    let added = quickAddStore.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
    impactHapticTrigger &+= 1
    AppSounds.log()
    presentToast(for: added)
    syncWidgets()
  }

  private func presentToast(for added: EntryActions.AddedEntry) {
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = EntryToastState(entryID: added.entryID, value: added.value, kind: .added)
    }
  }

  private func deletePreviewEntry(id: UUID) {
    guard let entry = periodEntries.first(where: { $0.id == id }) else { return }
    let toast = EntryToastState(
      entryID: entry.id,
      value: entry.amount,
      kind: .removed(timestamp: entry.timestamp)
    )
    EntryActions.deleteCounterEntry(id: id, in: modelContext)
    impactHapticTrigger &+= 1
    AppSounds.log()
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = toast
    }
    syncWidgets()
  }

  private func undoToast(_ toast: EntryToastState) {
    switch toast.kind {
    case .added:
      EntryActions.deleteCounterEntry(id: toast.entryID, in: modelContext)
    case .removed(let timestamp):
      _ = EntryActions.restoreCounterEntry(
        id: toast.entryID,
        value: toast.value,
        timestamp: timestamp,
        counter: counter,
        in: modelContext
      )
    }
    undoHapticTrigger &+= 1
    AppSounds.undo()
    withAnimation(MotionToken.entryInsert(reduceMotion: reduceMotion)) {
      entryToast = nil
    }
    syncWidgets()
  }

  private func syncWidgets() {
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}
