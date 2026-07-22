import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors
  @Environment(CounterSheetCoordinator.self) private var sheets
  @Environment(CounterFocusRouter.self) private var focusRouter
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]
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
  @AppStorage(AppAppearancePreference.compactModeEnabledKey) private var isCompactModeEnabled = false

  @State private var selectedPageID: String?
  @State private var isCounterListRevealed = false
  @State private var revealState = RevealState()
  @State private var containerWidth: CGFloat = 0
  @State private var pagerScrollState = PagerScrollState()
  @State private var hasAppliedInitialListReveal = false
  /// Selection to apply to the pager/compact stack once scrolling is enabled again. While the
  /// underlay list is open the main scroll view is disabled, and `scrollPosition` would otherwise
  /// write the still-visible page back over a programmatic selection (create / list tap).
  @State private var pendingScrollPageID: String?

  /// Compact stack still uses SwiftUI `scrollPosition`; the full pager is a UIKit scroll
  /// shell that owns offset/bounce so last-page jumps cannot be reintroduced by SwiftUI.
  private var compactScrollPosition: Binding<String?> {
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
    let _ = (isMonoEnabled, monoPaletteIndex, isTintEnabled, colorPackRaw)
    return counters.map { CounterAccent.forCounter($0) }
  }

  private var activeAccent: CounterAccent {
    let _ = (isMonoEnabled, monoPaletteIndex, isTintEnabled, colorPackRaw)
    guard let counter = activeCounter else {
      return CounterAccent.forCustomCounter(at: 0)
    }
    return CounterAccent.forCounter(counter)
  }

  private var activePageTitle: String {
    guard let activeCounter else { return "" }
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
  // `revealState.cardOffset` changes never invalidate this view's body. `locksScroll` is
  // already true for the whole duration of a drag/settle, so it stands in for "mid-transition".
  private var isRevealSettledOpen: Bool {
    isCounterListRevealed && !revealState.locksScroll
  }

  private var isRevealActive: Bool {
    isCounterListRevealed || revealState.locksScroll
  }

  var body: some View {
    GeometryReader { geometry in
      CounterUnderlayReveal(
        state: revealState,
        isRevealed: $isCounterListRevealed,
        isCompact: isCompactModeEnabled
      ) {
        AllCountersListView(
          scrollDisabled: revealState.locksScroll || !isRevealSettledOpen,
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
      if idStrings.isEmpty {
        selectedPageID = nil
        pendingScrollPageID = nil
        pagerScrollState.value = 0
        return
      }
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
      applyPendingDeepLinkIfNeeded()
    }
    .onChange(of: isRevealActive) { wasActive, active in
      if wasActive && !active {
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
      applyPendingDeepLinkIfNeeded()
    }
    .onChange(of: focusRouter.pendingCounterID) { _, _ in
      applyPendingDeepLinkIfNeeded()
    }
  }

  @ViewBuilder
  private func counterScreen() -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        CounterPagerPageRoot {
          if counters.isEmpty {
            emptyCountersState
          } else if isCompactModeEnabled {
            compactStack()
          } else {
            verticalPager(height: geometry.size.height)
          }
        }

        if !isCompactModeEnabled {
          if counters.isEmpty {
            emptyPagerToolbar
          } else {
            pagerToolbar
          }
        }
      }
    }
    .counterAccent(activeAccent)
    .counterDesignSystemFromColorScheme()
    .environment(\.counterPagerScrollState, pagerScrollState)
    .ignoresSafeArea(.keyboard)
  }

  private var emptyCountersState: some View {
    VStack(spacing: SpaceToken.u3) {
      Spacer(minLength: 0)

      Text("No counters yet")
        .counterTextStyle(.pageTitle)
        .multilineTextAlignment(.center)

      Text("Add a counter to start tracking.")
        .counterTextStyle(.bodySecondary, color: .secondary)
        .multilineTextAlignment(.center)

      PrimaryCapsuleButton(title: "Add counter", isEnabled: true) {
        sheets.present(.addCounter)
      }
      .padding(.top, SpaceToken.u1)
      .frame(maxWidth: GridToken.units(20))

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, SpaceToken.u4)
    .background(colors.surfacePrimary)
  }

  private var emptyPagerToolbar: some View {
    HStack(spacing: SpaceToken.toolbarIconSpacing) {
      CounterIconButton(icon: .listSortDescending) {
        openCounterList()
      }
      Spacer(minLength: 0)
    }
    .glassEffect(
      .clear.interactive(),
      in: .rect(
        topLeadingRadius: RadiusToken.scrollContainer,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: RadiusToken.scrollContainer
      )
    )
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
          // Same bounce lock as the paging pager — last-card overscroll + reveal cancel jumps.
          PagerScrollViewConfiguration()
          // Gate the UIKit pan only — never toggle SwiftUI `.scrollDisabled` mid-reveal.
          // Toggling `.scrollDisabled` reconciles content offset and jumps (worst on the last page).
          ScrollPanDisabler(
            isDisabled: (revealState.locksScroll || isCounterListRevealed) && pendingScrollPageID == nil
          )
        }
      }
      .scrollContentBackground(.hidden)
      .background(colors.surfacePrimary)
      .scrollPosition(id: compactScrollPosition, anchor: .top)
      .scrollIndicators(.hidden)
      .scrollClipDisabled(true)
      .onChange(of: pendingScrollPageID) { _, pageID in
        guard let pageID else { return }
        scrollProxy(proxy, to: pageID)
      }
    }
  }

  @ViewBuilder
  private func verticalPager(height: CGFloat) -> some View {
    VerticalPagerScrollView(
      pageHeight: height,
      pageIDs: pageIDs,
      selectedPageID: $selectedPageID,
      scrollState: pagerScrollState,
      revealState: revealState,
      isListRevealed: isCounterListRevealed,
      pendingPageID: pendingScrollPageID,
      onPendingHandled: { pendingScrollPageID = nil }
    ) {
      VStack(spacing: 0) {
        ForEach(counters) { counter in
          CustomCounterPageContent(counter: counter)
            .frame(height: height)
            .background(Color.clear)
        }
      }
      .counterPagerBackground(accents: pageAccents, scrollState: pagerScrollState)
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
    // Full pager consumes pending IDs in VerticalPagerScrollView; compact still uses
    // ScrollViewReader via onChange(of: pendingScrollPageID).
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
        revealState,
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
    // Widget / deep-link launches should land on the counter, not the list underlay.
    if focusRouter.pendingCounterID != nil {
      return
    }
    openCounterList(animated: false)
  }

  private func applyPendingDeepLinkIfNeeded() {
    guard let counterID = focusRouter.pendingCounterID else { return }
    let pageID = counterID.uuidString

    // Wait until the query has loaded at least once with data (or confirmed empty).
    guard !counters.isEmpty || hasAppliedInitialListReveal else { return }

    guard pageIDs.contains(pageID) else {
      // Counter was deleted or ID is stale — drop the link so launch isn't stuck.
      focusRouter.pendingCounterID = nil
      return
    }

    focusRouter.pendingCounterID = nil
    hasAppliedInitialListReveal = true
    scrollToPage(pageID, animated: false)
    if isRevealActive {
      collapseCounterList()
    } else {
      revealState.cardOffset = 0
      isCounterListRevealed = false
    }
  }

  private func selectPageFromList(_ pageID: String) {
    scrollToPage(pageID, animated: false)
    collapseCounterList()
  }

  private func collapseCounterList() {
    CounterUnderlayReveal<EmptyView, EmptyView>.lockRevealScrollForAnimation(
      revealState,
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
  @Environment(\.counterPagerScrollState) private var pagerScrollState

  let activePageTitle: String
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
    .allowsHitTesting(!(pagerScrollState?.isDragging ?? false) && !counterRevealIsDragging)
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
      .environment(CounterSheetCoordinator())
      .environment(CounterFocusRouter())
  }
}
