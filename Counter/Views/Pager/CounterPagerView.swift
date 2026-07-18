import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors
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

  @State private var selectedPageID: String?
  @State private var showButtonSettings = false
  @State private var showHistory = false
  @State private var showAddCounter = false
  @State private var isCounterListRevealed = false
  @State private var cardOffset: CGFloat = 0
  @State private var locksRevealScroll = false
  @State private var containerWidth: CGFloat = 0
  @State private var scrollProgress: CGFloat = 0
  @State private var isPagerDragging = false
  @State private var hasAppliedInitialListReveal = false
  /// Selection to apply to the pager/compact stack once scrolling is enabled again. While the
  /// underlay list is open the main scroll view is disabled, and `scrollPosition` would otherwise
  /// write the still-visible page back over a programmatic selection (create / list tap).
  @State private var pendingScrollPageID: String?
  /// Count of page-hosted sheets (custom amount / entry log) currently presented over the pager.
  /// Combined with the top-level sheet flags to freeze the pager's scroll inset while any sheet
  /// is up — otherwise the system's safe-area animation on present/dismiss shifts page content.
  @State private var pagerHostedSheetDepth = 0
  /// Resting page height, captured while no sheet is presented. Presenting a sheet shrinks the
  /// presenter's safe area (card-stack), which would otherwise resize pages mid-flight and shove
  /// content up. We hold this fixed for the duration of any presentation.
  @State private var restingPageHeight: CGFloat = 0

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
    activeCounter?.name ?? CustomCounter.untitledName
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

  private var isRevealSettledOpen: Bool {
    maxRevealOffset > 0 && cardOffset >= maxRevealOffset - 1
  }

  private var isRevealActive: Bool {
    isCounterListRevealed || cardOffset > 0.5
  }

  /// True while any sheet (top-level or page-hosted) is presented over the pager.
  private var isAnyPagerSheetPresented: Bool {
    showButtonSettings || showHistory || showAddCounter || pagerHostedSheetDepth > 0
  }

  var body: some View {
    GeometryReader { geometry in
      CounterUnderlayReveal(
        cardOffset: $cardOffset,
        isRevealed: $isCounterListRevealed,
        locksRevealScroll: $locksRevealScroll,
        isCompact: isCompactModeEnabled
      ) {
        AllCountersListView(
          scrollDisabled: locksRevealScroll || !isRevealSettledOpen,
          onSelectPage: selectPageFromList,
          onAddCounter: { showAddCounter = true }
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
          cardOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(
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
          cardOffset = maxRevealOffset
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      colors.surfacePrimary
        .ignoresSafeArea(edges: [.top, .horizontal])
    }
    .counterModalScrim(isPresented: showButtonSettings || showHistory || showAddCounter)
    .sheet(isPresented: $showButtonSettings) {
      buttonSettingsSheet
    }
    .sheet(isPresented: $showHistory) {
      if let counter = activeCounter {
        CounterHistoryView(counter: counter)
      }
    }
    .sheet(isPresented: $showAddCounter) {
      CreateCounterView { counter in
        // Sheet dismiss carries an animation transaction — apply selection without it so the
        // pager/compact stack jumps to the new counter instead of fighting the dismiss spring.
        scrollToPage(counter.id.uuidString, animated: false)
      }
    }
    .environment(\.onPagerHostedSheetPresent, notePagerHostedSheetPresented)
    .environment(\.onPagerHostedSheetDismiss, notePagerHostedSheetDismissed)
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
        flushPendingScroll()
      }
    }
    .onAppear {
      if selectedPageID == nil {
        selectedPageID = counters.first?.id.uuidString
      }
      syncScrollProgressToSelectedPage()
    }
  }

  @ViewBuilder
  private func counterScreen() -> some View {
    GeometryReader { geometry in
      // While a sheet is up, hold the last resting height so the safe-area animation can't
      // resize pages and shift content. Otherwise track the live geometry height.
      let pageHeight = (isAnyPagerSheetPresented && restingPageHeight > 0)
        ? restingPageHeight
        : geometry.size.height

      ZStack(alignment: .top) {
        CounterPagerPageRoot {
          if isCompactModeEnabled {
            compactStack()
          } else {
            verticalPager(height: pageHeight)
          }
        }

        if !isCompactModeEnabled {
          pagerToolbar
        }
      }
      .onAppear {
        if restingPageHeight < 1 {
          restingPageHeight = geometry.size.height
        }
      }
      .onChange(of: geometry.size.height) { _, newHeight in
        guard !isAnyPagerSheetPresented, newHeight > 1 else { return }
        // Only grow: the presenter's safe-area animation only ever shrinks height transiently,
        // and a page-hosted sheet's "presented" flag can arrive a beat late.
        restingPageHeight = max(restingPageHeight, newHeight)
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
          PagerScrollInsetLock(isSheetPresented: isAnyPagerSheetPresented)
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
        .counterPagerBackground(accents: pageAccents, scrollProgress: scrollProgress)
        .background {
          ScrollPanDisabler(isDisabled: locksRevealScroll)
          PagerScrollInsetLock(isSheetPresented: isAnyPagerSheetPresented)
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
        scrollProgress = offset / height
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
    scrollProgress = CGFloat(index)
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

  private func flushPendingScroll() {
    guard let pageID = pendingScrollPageID ?? selectedPageID,
          pageIDs.contains(pageID) else { return }
    queuePagerScroll(to: pageID)
  }

  private func notePagerHostedSheetPresented() {
    pagerHostedSheetDepth += 1
  }

  private func notePagerHostedSheetDismissed() {
    pagerHostedSheetDepth = max(0, pagerHostedSheetDepth - 1)
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
        cardOffset = maxOffset
        isCounterListRevealed = true
      }
    } else {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        cardOffset = maxOffset
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

  private func presentHistory(for counter: CustomCounter) {
    selectedPageID = counter.id.uuidString
    showHistory = true
  }

  private func presentButtonSettings(for counter: CustomCounter) {
    selectedPageID = counter.id.uuidString
    showButtonSettings = true
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
      cardOffset = 0
      isCounterListRevealed = false
    }
  }

  @ViewBuilder
  private var pagerToolbar: some View {
    PagerToolbarBar(
      activePageTitle: activePageTitle,
      isPagerDragging: isPagerDragging,
      onOpenCounterList: { openCounterList() },
      onShowHistory: { showHistory = true },
      onShowButtonSettings: { showButtonSettings = true }
    )
  }

  @ViewBuilder
  private var buttonSettingsSheet: some View {
    if let counter = activeCounter {
      CounterSettingsView(
        title: "\(counter.name) Settings",
        values: counter.buttonValues,
        counter: counter,
        onSave: { save in
          if let name = save.name {
            counter.name = CustomCounter.normalizedName(from: name)
          }
          counter.buttonValues = save.buttonValues
          counter.goal = save.goal
          counter.resetPeriod = save.resetPeriod
          counter.resetAnchorDay = save.resetAnchorDay
          counter.goalDirection = save.goalDirection
          if let paletteIndex = save.paletteIndex {
            counter.paletteIndex = paletteIndex
          }
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          WatchSyncEngine.publishCounterUpsert(counter)
        },
        onDelete: {
          let counterID = counter.id
          modelContext.delete(counter)
          WidgetSnapshot.reloadTimelines()
          WatchSyncEngine.publishCounterDelete(counterID)
        },
        onPaletteChange: { index in
          counter.paletteIndex = index
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          WatchSyncEngine.publishCounterUpsert(counter)
        }
      )
    }
  }
}

private struct PagerToolbarBar: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  let activePageTitle: String
  let isPagerDragging: Bool
  let onOpenCounterList: () -> Void
  let onShowHistory: () -> Void
  let onShowButtonSettings: () -> Void

  var body: some View {
    VStack(spacing: 0) {
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
      .padding(.horizontal, SpaceToken.toolbarHorizontal)
      .padding(.top, SpaceToken.toolbarTop)
      .padding(.bottom, SpaceToken.toolbarBottom)

      Rectangle()
        .fill(colors.textPrimary)
        .frame(height: BorderToken.toolbar)
        .padding(.horizontal, SpaceToken.u1)
    }
    .background(Color.clear)
    .allowsHitTesting(!isPagerDragging && !counterRevealIsDragging)
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
  }
}
