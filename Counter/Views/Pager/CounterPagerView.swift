import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors
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

  @State private var selectedPageID: String?
  @State private var isCounterListRevealed = false
  @State private var revealState = RevealState()
  @State private var locksRevealScroll = false
  @State private var containerWidth: CGFloat = 0
  @State private var pagerScrollState = PagerScrollState()
  @State private var isPagerDragging = false
  @State private var hasAppliedInitialListReveal = false
  /// Selection to apply to the pager/compact stack once scrolling is enabled again. While the
  /// underlay list is open the main scroll view is disabled, and `scrollPosition` would otherwise
  /// write the still-visible page back over a programmatic selection (create / list tap).
  @State private var pendingScrollPageID: String?
  @State private var pagerSnapTrigger = 0

  private var selectedPageIndex: Int {
    guard let selectedPageID,
          let index = pageIDs.firstIndex(of: selectedPageID) else { return 0 }
    return index
  }

  /// Two-way `scrollPosition` binding that ignores scroll-view writebacks while the list
  /// reveal has the main pager locked — keeps create/list selection from being clobbered.
  private var pagerScrollPosition: Binding<String?> {
    Binding(
      get: { selectedPageID },
      set: { newValue in
        guard !isRevealActive else { return }
        selectedPageID = newValue
        syncScrollProgressToSelectedPage()
      }
    )
  }

  private var pageIDs: [String] {
    counters.map(\.id.uuidString)
  }

  private var activeCounter: CustomCounter? {
    guard let selectedPageID else { return counters.first }
    return counters.first { $0.id.uuidString == selectedPageID }
  }

  private var pageAccents: [CounterAccent] {
    let _ = (isMonoEnabled, monoPaletteIndex)
    return counters.map { CounterAccent.forCounter($0) }
  }

  private var activeAccent: CounterAccent {
    let _ = (isMonoEnabled, monoPaletteIndex)
    guard let counter = activeCounter else {
      return CounterAccent.forCustomCounter(at: 0)
    }
    return CounterAccent.forCounter(counter)
  }

  private var activePageTitle: String {
    guard let activeCounter else { return CustomCounter.untitledName }
    return CounterFormatting.titleWithUnit(
      name: activeCounter.name,
      unit: activeCounter.effectiveUnit
    )
  }

  private var settleSpring: Animation {
    MotionToken.settle(reduceMotion: reduceMotion)
  }

  private var maxRevealOffset: CGFloat {
    RevealToken.openOffset(
      forScreenWidth: max(containerWidth, 1),
      isCompact: isCompactModeEnabled
    )
  }

  // Discrete flags derived from settled state, not the live drag offset, so that per-frame
  // `revealState.cardOffset` changes never invalidate this view's body. `locksRevealScroll` is
  // already true for the whole duration of a drag/settle, so it stands in for "mid-transition".
  private var isRevealSettledOpen: Bool {
    isCounterListRevealed && !locksRevealScroll
  }

  private var isRevealActive: Bool {
    isCounterListRevealed || locksRevealScroll
  }

  var body: some View {
    GeometryReader { geometry in
      CounterUnderlayReveal(
        state: revealState,
        isRevealed: $isCounterListRevealed,
        locksRevealScroll: $locksRevealScroll,
        isCompact: isCompactModeEnabled
      ) {
        AllCountersListView(
          scrollDisabled: locksRevealScroll || !isRevealSettledOpen,
          onSelectPage: selectPageFromList,
          onAddCounter: { sheets.present(.addCounter) }
        )
      } card: {
        counterScreen()
      }
      .onAppear {
        containerWidth = geometry.size.width
        applyInitialListRevealIfNeeded(width: geometry.size.width)
      }
      .onChange(of: geometry.size.width) { _, newWidth in
        containerWidth = newWidth
        if isCounterListRevealed {
          revealState.cardOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(
            for: newWidth,
            isCompact: isCompactModeEnabled
          )
        } else {
          applyInitialListRevealIfNeeded(width: newWidth)
        }
      }
      .onChange(of: isCompactModeEnabled) { _, _ in
        guard isCounterListRevealed else { return }
        withAnimation(settleSpring) {
          revealState.cardOffset = maxRevealOffset
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      colors.surfacePrimary
        .ignoresSafeArea(edges: [.top, .horizontal])
    }
    .counterModalScrim(isPresented: sheets.isPagerScrimActive)
    .onChange(of: counters.map(\.id)) { _, ids in
      let idStrings = ids.map(\.uuidString)
      if let selectedPageID, !idStrings.contains(selectedPageID) {
        scrollToPage(idStrings.first, animated: false)
        return
      }
      // After insert, the new page exists in the query — flush any deferred scroll target.
      if let pendingScrollPageID, idStrings.contains(pendingScrollPageID) {
        scrollToPage(pendingScrollPageID, animated: false)
      } else {
        syncScrollProgressToSelectedPage()
      }
    }
    .onChange(of: isRevealActive) { wasActive, active in
      if wasActive && !active {
        pagerSnapTrigger += 1
        flushPendingScroll()
        syncScrollProgressToSelectedPage()
      }
    }
    .onAppear {
      if selectedPageID == nil {
        selectedPageID = counters.first?.id.uuidString
      }
      syncScrollProgressToSelectedPage()
      sheets.onCounterCreated = { counter in
        scrollToPage(counter.id.uuidString, animated: false)
      }
    }
  }

  @ViewBuilder
  private func counterScreen() -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        CounterPagerPageRoot {
          if isCompactModeEnabled {
            compactStack()
          } else {
            verticalPager(height: geometry.size.height)
          }
        }

        if !isCompactModeEnabled {
          pagerToolbar
        }
      }
    }
    .counterAccent(activeAccent)
    .counterDesignSystemFromColorScheme()
    .counterPagerDragging(isPagerDragging)
    .ignoresSafeArea(.keyboard)
  }

  @ViewBuilder
  private func compactStack() -> some View {
    ScrollViewReader { proxy in
      ScrollView(.vertical) {
        VStack(spacing: CompactCardToken.cardSpacing) {
          ForEach(counters) { counter in
            CustomCounterPageContent(
              counter: counter,
              isCompact: true,
              onShowHistory: { presentHistory(for: counter) },
              onShowButtonSettings: { presentButtonSettings(for: counter) }
            )
            .id(counter.id.uuidString)
          }
        }
        .scrollTargetLayout()
        .padding(.bottom, SpaceToken.pageFooterBottom)
        .background {
          ScrollPanDisabler(isDisabled: locksRevealScroll)
        }
      }
      .scrollContentBackground(.hidden)
      .background(colors.surfacePrimary)
      .scrollPosition(id: pagerScrollPosition, anchor: .top)
      .scrollIndicators(.hidden)
      // Keep user scroll locked while the list is open, but allow a brief unlock while a
      // pending programmatic scroll is in flight so ScrollViewReader.scrollTo can move pages.
      .scrollDisabled(locksRevealScroll || (isRevealActive && pendingScrollPageID == nil))
      .scrollClipDisabled(!isRevealActive)
      .onChange(of: pendingScrollPageID) { _, pageID in
        guard let pageID else { return }
        scrollProxy(proxy, to: pageID)
      }
    }
  }

  @ViewBuilder
  private func verticalPager(height: CGFloat) -> some View {
    ScrollViewReader { proxy in
      ScrollView(.vertical) {
        VStack(spacing: 0) {
          ForEach(counters) { counter in
            CustomCounterPageContent(counter: counter)
              .frame(height: height)
              .background(Color.clear)
              .id(counter.id.uuidString)
          }
        }
        .scrollTargetLayout()
        .counterPagerBackground(accents: pageAccents, scrollState: pagerScrollState)
        .background {
          ScrollPanDisabler(
            isDisabled: locksRevealScroll,
            pageIndex: selectedPageIndex,
            snapTrigger: pagerSnapTrigger
          )
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color.clear)
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: pagerScrollPosition, anchor: .top)
      .scrollIndicators(.hidden)
      .scrollDisabled(locksRevealScroll || (isRevealActive && pendingScrollPageID == nil))
      .scrollClipDisabled(!isRevealActive)
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top
      } action: { _, offset in
        guard height > 0, !isRevealActive else { return }
        pagerScrollState.value = offset / height
      }
      .onScrollPhaseChange { _, newPhase in
        isPagerDragging = newPhase != .idle
      }
      .onChange(of: pendingScrollPageID) { _, pageID in
        guard let pageID else { return }
        scrollProxy(proxy, to: pageID)
      }
    }
  }

  private func syncScrollProgressToSelectedPage() {
    guard let selectedPageID,
          let index = pageIDs.firstIndex(of: selectedPageID) else { return }
    pagerScrollState.value = CGFloat(index)
  }

  /// Sets the active page and keeps pager accent progress in sync. Pass `animated: false`
  /// for list taps and post-create jumps so scroll settles instantly.
  private func scrollToPage(_ pageID: String?, animated: Bool) {
    guard let pageID else {
      selectedPageID = nil
      pendingScrollPageID = nil
      return
    }

    if animated {
      selectedPageID = pageID
    } else {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        selectedPageID = pageID
      }
    }
    syncScrollProgressToSelectedPage()
    // Drive ScrollViewReader via pendingScrollPageID. The scrollPosition binding ignores
    // writebacks while the list is revealed, so this selection sticks until the proxy scrolls.
    queuePagerScroll(to: pageID)
  }

  /// Applies a deferred programmatic page scroll after the list reveal closes. Only runs when
  /// a list/create selection queued `pendingScrollPageID` — do not scroll to the current page
  /// on every close or dragging back to the counter card jumps the pager.
  private func flushPendingScroll() {
    guard let pageID = pendingScrollPageID,
          pageIDs.contains(pageID) else { return }
    queuePagerScroll(to: pageID)
  }

  private func presentHistory(for counter: CustomCounter) {
    selectedPageID = counter.id.uuidString
    sheets.present(.history(counterID: counter.id))
  }

  private func presentButtonSettings(for counter: CustomCounter) {
    selectedPageID = counter.id.uuidString
    sheets.present(.buttonSettings(counterID: counter.id))
  }

  private func queuePagerScroll(to pageID: String) {
    if pendingScrollPageID != pageID {
      pendingScrollPageID = pageID
      return
    }
    // Value unchanged — bounce through nil on the next turn so onChange still fires.
    pendingScrollPageID = nil
    Task { @MainActor in
      pendingScrollPageID = pageID
    }
  }

  private func scrollProxy(_ proxy: ScrollViewProxy, to pageID: String) {
    guard pageIDs.contains(pageID) else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      proxy.scrollTo(pageID, anchor: .top)
      selectedPageID = pageID
    }
    pendingScrollPageID = nil
    syncScrollProgressToSelectedPage()
  }

  private func openCounterList(animated: Bool = true) {
    let width = max(containerWidth, 1)
    let maxOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(
      for: width,
      isCompact: isCompactModeEnabled
    )
    if animated {
      CounterUnderlayReveal<EmptyView, EmptyView>.lockRevealScrollForAnimation(
        $locksRevealScroll,
        reduceMotion: reduceMotion
      )
    }
    if animated {
      withAnimation(settleSpring) {
        revealState.cardOffset = maxOffset
        isCounterListRevealed = true
      }
    } else {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        revealState.cardOffset = maxOffset
        isCounterListRevealed = true
      }
    }
  }

  private func applyInitialListRevealIfNeeded(width: CGFloat) {
    guard !hasAppliedInitialListReveal, width > 0 else { return }
    hasAppliedInitialListReveal = true
    containerWidth = width
    openCounterList(animated: false)
  }

  private func selectPageFromList(_ pageID: String) {
    scrollToPage(pageID, animated: false)
    collapseCounterList()
  }

  private func collapseCounterList() {
    CounterUnderlayReveal<EmptyView, EmptyView>.lockRevealScrollForAnimation(
      $locksRevealScroll,
      reduceMotion: reduceMotion
    )
    withAnimation(settleSpring) {
      revealState.cardOffset = 0
      isCounterListRevealed = false
    }
  }

  @ViewBuilder
  private var pagerToolbar: some View {
    PagerToolbarBar(
      activePageTitle: activePageTitle,
      isPagerDragging: isPagerDragging,
      onOpenCounterList: { openCounterList() },
      onShowHistory: {
        guard let counter = activeCounter else { return }
        sheets.present(.history(counterID: counter.id))
      },
      onShowButtonSettings: {
        guard let counter = activeCounter else { return }
        sheets.present(.buttonSettings(counterID: counter.id))
      }
    )
  }
}

private struct PagerToolbarBar: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  let activePageTitle: String
  let isPagerDragging: Bool
  let onOpenCounterList: () -> Void
  let onShowHistory: () -> Void
  let onShowButtonSettings: () -> Void

  private var accentTint: Color {
    (counterAccent ?? .forCustomCounter(at: 0)).palette.background(for: colorScheme)
  }

  var body: some View {
    HStack(spacing: SpaceToken.toolbarIconSpacing) {
      CounterIconButton(icon: .listSortDescending, action: onOpenCounterList)

      Text(activePageTitle)
        .counterTextStyle(.pageTitle)
        .lineLimit(1)

      Spacer(minLength: 0)

      HStack(spacing: SpaceToken.toolbarIconSpacing) {
        CounterIconButton(icon: .chartBar, action: onShowHistory)
        CounterIconButton(icon: .slidersHorizontal, action: onShowButtonSettings)
      }
    }
    .glassEffect(
      .clear.tint(accentTint).interactive(),
      in: .rect(
        topLeadingRadius: RadiusToken.scrollContainer,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: RadiusToken.scrollContainer
      )
    )
    .allowsHitTesting(!isPagerDragging && !counterRevealIsDragging)
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
      .environment(CounterSheetCoordinator())
  }
}
