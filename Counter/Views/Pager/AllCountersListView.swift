import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.modelContext) private var modelContext
  @Environment(CounterSheetCoordinator.self) private var sheets
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(AppAppearancePreference.compactModeEnabledKey) private var isCompactModeEnabled = false
  @State private var editMode: EditMode = .inactive

  var scrollDisabled = false
  let onSelectPage: (String) -> Void
  var onAddCounter: (() -> Void)?

  private var isEditing: Bool {
    editMode.isEditing
  }

  var body: some View {
    List {
      ForEach(counters) { counter in
        counterRow(for: counter)
          .listRowInsets(EdgeInsets(
            top: SpaceToken.u1 / 2,
            leading: SpaceToken.pageMargin,
            bottom: SpaceToken.u1 / 2,
            trailing: SpaceToken.pageMargin
          ))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .onDelete(perform: deleteCounters)
      .onMove(perform: moveCounters)

      if let onAddCounter, !isEditing {
        NewCounterButton(action: onAddCounter)
          .listRowInsets(EdgeInsets(
            top: SpaceToken.u1 / 2,
            leading: SpaceToken.pageMargin,
            bottom: SpaceToken.u1 / 2,
            trailing: SpaceToken.pageMargin
          ))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .id("add-new-counter")
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .scrollDisabled(scrollDisabled)
    .background {
      ScrollPanDisabler(isDisabled: scrollDisabled)
    }
    .scrollClipDisabled()
    .scrollEdgeEffectStyle(.soft, for: .top)
    .environment(\.editMode, $editMode)
    .safeAreaPadding(.bottom, SpaceToken.componentPadding)
    .safeAreaBar(edge: .top, spacing: 0) {
      listHeader
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(colors.surfacePrimary)
    .counterModalScrim(isPresented: sheets.route == .appSettings)
    .counterDesignSystemFromColorScheme()
  }

  private var listHeader: some View {
    HStack {
      if isEditing {
        Button("Done") {
          withAnimation {
            editMode = .inactive
          }
        }
        .counterTextStyle(.settingsRowLabel)
      }

      Spacer(minLength: 0)

      HStack(spacing: SpaceToken.toolbarIconSpacing) {
        if let onAddCounter, !isEditing {
          CounterIconButton(icon: .plus, action: onAddCounter)
        }
        CounterIconButton(icon: .cog) {
          sheets.present(.appSettings)
        }
      }
      .glassEffect(.regular.interactive())
      .padding(.trailing, SpaceToken.u1)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func counterRow(for counter: CustomCounter) -> some View {
    let _ = (isMonoEnabled, monoPaletteIndex)
    let total = counter.currentTotal()
    let progress = counter.currentProgress()

    CounterListCard(
      accent: .forCounter(counter),
      title: counter.name,
      value: cardValue(for: progress, total: total),
      caption: cardCaption(for: progress, counter: counter),
      ringProgress: progress,
      isCompact: isCompactModeEnabled
    ) {
      guard !isEditing else { return }
      onSelectPage(counter.id.uuidString)
    }
    .id(counter.id)
    .simultaneousGesture(
      LongPressGesture(minimumDuration: 0.45).onEnded { _ in
        guard !isEditing else { return }
        AppHaptics.impact()
        withAnimation {
          editMode = .active
        }
      }
    )
  }

  private func cardValue(for progress: GoalProgress?, total: Double) -> String {
    progress?.heroValue ?? CounterFormatting.amount(total)
  }

  private func cardCaption(for progress: GoalProgress?, counter: CustomCounter) -> String {
    progress?.heroSubtitle.capitalized ?? counter.resetPeriod.periodCaption
  }

  private func deleteCounters(at offsets: IndexSet) {
    for index in offsets {
      let counter = counters[index]
      let counterID = counter.id
      modelContext.delete(counter)
      WatchSyncEngine.publishCounterDelete(counterID)
    }
    WidgetSnapshot.reloadTimelines()
  }

  private func moveCounters(from source: IndexSet, to destination: Int) {
    var ordered = counters
    ordered.move(fromOffsets: source, toOffset: destination)
    for (index, counter) in ordered.enumerated() {
      counter.sortOrder = Double(index)
    }
    WatchSyncEngine.publishFullSnapshot(in: modelContext)
  }
}

#Preview {
  AllCountersListView { _ in }
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
