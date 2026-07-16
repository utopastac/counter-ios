import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

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

  @Namespace private var sheetTransition

  private var pageIDs: [String] {
    counters.map(\.id.uuidString)
  }

  private var activeCounter: CustomCounter? {
    guard let selectedPageID else { return counters.first }
    return counters.first { $0.id.uuidString == selectedPageID }
  }

  private var pageAccents: [CounterAccent] {
    counters.map { CounterAccent.forCounter($0) }
  }

  private var activeAccent: CounterAccent {
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
    RevealToken.openOffset(forScreenWidth: max(containerWidth, 1))
  }

  private var isRevealSettledOpen: Bool {
    maxRevealOffset > 0 && cardOffset >= maxRevealOffset - 1
  }

  private var isRevealActive: Bool {
    isCounterListRevealed || cardOffset > 0.5
  }

  var body: some View {
    GeometryReader { geometry in
      CounterUnderlayReveal(
        cardOffset: $cardOffset,
        isRevealed: $isCounterListRevealed,
        locksRevealScroll: $locksRevealScroll
      ) {
        AllCountersListView(
          scrollDisabled: locksRevealScroll || !isRevealSettledOpen,
          transitionNamespace: sheetTransition,
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
          cardOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(for: newWidth)
        } else {
          applyInitialListRevealIfNeeded(width: newWidth)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      colors.surfacePrimary
        .ignoresSafeArea(edges: [.top, .horizontal])
    }
    .sheet(isPresented: $showButtonSettings) {
      buttonSettingsSheet
        .navigationTransition(.zoom(sourceID: SheetTransitionID.buttonSettings, in: sheetTransition))
    }
    .sheet(isPresented: $showHistory) {
      if let counter = activeCounter {
        CounterHistoryView(counter: counter)
          .navigationTransition(.zoom(sourceID: SheetTransitionID.history, in: sheetTransition))
      }
    }
    .sheet(isPresented: $showAddCounter) {
      CreateCounterView { counter in
        selectedPageID = counter.id.uuidString
      }
      .navigationTransition(.zoom(sourceID: SheetTransitionID.addCounter, in: sheetTransition))
    }
    .onChange(of: counters.map(\.id)) { _, _ in
      if let selectedPageID, !pageIDs.contains(selectedPageID) {
        self.selectedPageID = counters.first?.id.uuidString
      }
      syncScrollProgressToSelectedPage()
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
      ZStack(alignment: .top) {
        CounterPagerPageRoot {
          verticalPager(height: geometry.size.height)
        }

        pagerToolbar
      }
    }
    .counterAccent(activeAccent)
    .counterDesignSystemFromColorScheme()
    .counterPagerDragging(isPagerDragging)
  }

  @ViewBuilder
  private func verticalPager(height: CGFloat) -> some View {
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
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.clear)
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $selectedPageID, anchor: .top)
    .scrollIndicators(.hidden)
    .scrollDisabled(locksRevealScroll || isRevealActive)
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
  }

  private func syncScrollProgressToSelectedPage() {
    guard let selectedPageID,
          let index = pageIDs.firstIndex(of: selectedPageID) else { return }
    scrollProgress = CGFloat(index)
  }

  private func openCounterList(animated: Bool = true) {
    let width = max(containerWidth, 1)
    let maxOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(for: width)
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

  private func selectPageFromList(_ pageID: String) {
    if pageID != selectedPageID {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        selectedPageID = pageID
      }
    }
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
      transitionNamespace: sheetTransition,
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
        },
        onDelete: {
          modelContext.delete(counter)
          WidgetSnapshot.reloadTimelines()
        },
        onPaletteChange: { index in
          counter.paletteIndex = index
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
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
  let transitionNamespace: Namespace.ID
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
            .matchedTransitionSource(id: SheetTransitionID.history, in: transitionNamespace)

          CounterIconButton(icon: .slidersHorizontal, action: onShowButtonSettings)
            .matchedTransitionSource(id: SheetTransitionID.buttonSettings, in: transitionNamespace)
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
