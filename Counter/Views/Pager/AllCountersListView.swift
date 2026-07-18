import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.semanticColors) private var colors
  @Environment(CounterSheetCoordinator.self) private var sheets
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(AppAppearancePreference.compactModeEnabledKey) private var isCompactModeEnabled = false

  var scrollDisabled = false
  let onSelectPage: (String) -> Void
  var onAddCounter: (() -> Void)?

  var body: some View {
    ScrollView {
      listCards
        .padding(.horizontal, SpaceToken.pageMargin)
        .padding(.bottom, SpaceToken.pageFooterBottom)
        .background {
          ScrollPanDisabler(isDisabled: scrollDisabled)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .safeAreaPadding(.bottom, SpaceToken.componentPadding)
    .scrollClipDisabled()
    .scrollDisabled(scrollDisabled)
    .safeAreaInset(edge: .top, spacing: 0) {
      listHeader
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(colors.surfacePrimary)
    .counterModalScrim(isPresented: sheets.route == .appSettings)
    .counterDesignSystemFromColorScheme()
  }

  private var listHeader: some View {
    HStack {
      Spacer()
      HStack(spacing: SpaceToken.toolbarIconSpacing) {
        if let onAddCounter {
          CounterIconButton(icon: .plus, action: onAddCounter)
        }
        CounterIconButton(icon: .cog) {
          sheets.present(.appSettings)
        }
      }
    }
    .padding(.horizontal, SpaceToken.pageMargin)
    .padding(.top, SpaceToken.toolbarTop)
    .padding(.bottom, SpaceToken.u2)
    .background(colors.surfacePrimary)
  }

  private var listCards: some View {
    let _ = (isMonoEnabled, monoPaletteIndex)
    return VStack(alignment: .leading, spacing: SpaceToken.u1) {
      ForEach(counters) { counter in
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
          onSelectPage(counter.id.uuidString)
        }
        .id(counter.id)
      }

      if let onAddCounter {
        NewCounterButton(action: onAddCounter)
          .id("add-new-counter")
      }
    }
    // Rebuild list chrome when membership changes so newly inserted rows don't inherit
    // stale hit-testing from the previous "Add new" slot after sheet dismiss.
    .id(counters.map(\.id))
    .transaction { transaction in
      transaction.animation = nil
    }
  }

  private func cardValue(for progress: GoalProgress?, total: Int) -> String {
    progress?.heroValue ?? "\(total)"
  }

  private func cardCaption(for progress: GoalProgress?, counter: CustomCounter) -> String {
    progress?.heroSubtitle.capitalized ?? counter.resetPeriod.periodCaption
  }
}

#Preview {
  AllCountersListView { _ in }
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
