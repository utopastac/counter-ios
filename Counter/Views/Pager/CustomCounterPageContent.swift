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
  @AppStorage(AppAppearancePreference.defaultCounterHeaderDisplayKey)
  private var defaultHeaderDisplayRaw = CounterHeaderDisplay.number.rawValue

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

  /// Re-reads global default so app-settings changes invalidate the page.
  private var startsWithStatsHeader: Bool {
    let globalDefault = CounterHeaderDisplay(rawValue: defaultHeaderDisplayRaw) ?? .number
    return counter.overrideShowsStatsHeader ?? globalDefault.showsStats
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
        valueText: entry.previewText
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
          label: counter.kind.requiresCap ? "Limit" : "Target"
        )
      )
    }

    rows.append(
      CounterStatRow(
        id: "added",
        value: CounterFormatting.amount(periodTotal),
          label: counter.kind == .number ? "Added" : "Logged"
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
          statRows: statRows,
          ringProgress: counter.currentProgress(),
          ringWidthOverride: counter.overrideProgressRingWidth,
          ringGlowOverride: counter.overrideProgressRingGlow,
          startsWithStatsHeader: startsWithStatsHeader,
          onShowHistory: onShowHistory,
          onShowButtonSettings: onShowButtonSettings
        ) {
          captureFooter(buttonHeight: CompactCardToken.quickAddHeight)
        } toast: {
          if let entryToast {
            EntryAddedToast(value: entryToast.value, kind: entryToast.kind, label: toastLabel(for: entryToast)) {
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
              ringWidthOverride: counter.overrideProgressRingWidth,
            ringGlowOverride: counter.overrideProgressRingGlow,
            startsWithStatsHeader: startsWithStatsHeader
          ) {
            VStack(alignment: .leading, spacing: 0) {
              if counter.kind == .number {
                CompactEntryLogPreview(
                  items: previewItems,
                  onEdit: { entryID in
                    editPreviewEntry(id: entryID)
                  },
                  onDelete: { entryID in
                    deletePreviewEntry(id: entryID)
                  }
                )
              } else {
                journalEntries(maxTextRows: EntryLogPreviewLimit.count)
              }

              Button {
                guard !counterRevealIsDragging else { return }
                onShowHistory()
              } label: {
                EntryLogAllEntriesControl()
                  .frame(maxWidth: .infinity, alignment: .center)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.noHighlight)
            }
          } footer: {
            captureFooter()
          } toast: {
            if let entryToast {
              EntryAddedToast(value: entryToast.value, kind: entryToast.kind, label: toastLabel(for: entryToast)) {
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
      guard counter.kind == .number else { return }
      migratePresetButtons(for: counter)
    }
    .onChange(of: periodTotal) { _, _ in
      syncWidgets()
    }
    .task(id: entryToast) {
      guard let toast = entryToast else { return }
      try? await Task.sleep(for: .seconds(EntryActions.entryToastDuration))
      guard !Task.isCancelled else { return }
      if case .removed(let record) = toast.kind {
        JournalMediaStore.purge(relativePath: record.mediaRelativePath)
      }
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
    let stored = QuickAddConfiguration.presetsReplacingLegacyCalorieDuplicate(counter.presetAmounts)
    let filled = QuickAddConfiguration.filledPresets(
      from: stored,
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

  private func editPreviewEntry(id: UUID) {
    guard let entry = periodEntries.first(where: { $0.id == id }) else { return }
    sheets.present(.editEntry(entryID: entry.id, value: entry.amount))
  }

  private func deletePreviewEntry(id: UUID) {
    guard let record = EntryActions.removeCounterEntryForUndo(id: id, in: modelContext) else { return }
    let toast = EntryToastState(
      entryID: record.entryID,
      value: record.value,
      kind: .removed(record)
    )
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
    case .removed(let record):
      let mediaPath = JournalMediaStore.restore(
        trashedRelativePath: record.mediaRelativePath,
        entryID: record.entryID
      )
      _ = EntryActions.restoreCounterEntry(
        id: record.entryID,
        value: record.value,
        timestamp: record.timestamp,
        counter: counter,
        noteText: record.noteText,
        mediaRelativePath: mediaPath,
        latitude: record.latitude,
        longitude: record.longitude,
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

  private var showsJournalComposer: Bool {
    switch counter.kind {
    case .note, .voice, .place, .book, .movie:
      true
    case .number, .photo, .sketch:
      false
    }
  }

  @ViewBuilder
  private func journalEntries(maxTextRows: Int) -> some View {
    switch counter.kind {
    case .photo, .sketch:
      JournalMediaCapture(
        counter: counter,
        onAdded: handleJournalAdd,
        onDelete: { deletePreviewEntry(id: $0) }
      )
    case .note, .voice, .place, .book, .movie:
      JournalEntryList(
        entries: Array(periodEntries.prefix(maxTextRows)),
        kind: counter.kind,
        truncates: true,
        onDelete: { deletePreviewEntry(id: $0) }
      )
    case .number:
      EmptyView()
    }
  }

  private func handleJournalAdd(_ added: EntryActions.AddedEntry) {
    impactHapticTrigger &+= 1
    AppSounds.log()
    presentToast(for: added)
    syncWidgets()
  }

  @ViewBuilder
  private func captureFooter(buttonHeight: CGFloat = SizeToken.quickAddHeight) -> some View {
    if counter.kind == .number {
      CompactQuickAddGrid(
        values: counter.presetAmounts,
        defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name),
        buttonHeight: buttonHeight
      ) { value in
        addEntryQuick(value)
      } onCustom: {
        sheets.present(.customAmount(counterID: counter.id))
      }
    } else if isCompact {
      VStack(alignment: .leading, spacing: SpaceToken.u2) {
        if showsJournalComposer {
          JournalCaptureFooter(counter: counter, onAdded: handleJournalAdd)
        }
        journalEntries(maxTextRows: 2)
      }
    } else if showsJournalComposer {
      JournalCaptureFooter(counter: counter, onAdded: handleJournalAdd)
    }
  }

  private func toastLabel(for toast: EntryToastState) -> String {
    let verb = if case .added = toast.kind { "added" } else { "removed" }
    if counter.kind == .number {
      return "\(CounterFormatting.amount(toast.value)) \(verb)"
    }
    return "\(counter.kind.entryNoun) \(verb)"
  }

  private func syncWidgets() {
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}
