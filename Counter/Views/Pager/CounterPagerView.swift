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

  private var pageIDs: [String] {
    counters.map(\.id.uuidString)
  }

  private var activeCounter: CustomCounter? {
    guard let selectedPageID else { return counters.first }
    return counters.first { $0.id.uuidString == selectedPageID }
  }

  private var pageAccents: [CounterAccent] {
    counters.enumerated().map { CounterAccent.forCustomCounter(at: $0.offset) }
  }

  private var activeAccent: CounterAccent {
    guard
      let counter = activeCounter,
      let index = counters.firstIndex(where: { $0.id == counter.id })
    else {
      return CounterAccent.forCustomCounter(at: 0)
    }
    return .forCustomCounter(at: index)
  }

  private var activePageTitle: String {
    activeCounter?.name ?? "Counter"
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
          embedded: true,
          scrollDisabled: locksRevealScroll || !isRevealSettledOpen,
          onSelectPage: selectPageFromList,
          onClose: collapseCounterList,
          onAddCounter: { showAddCounter = true }
        )
      } card: {
        counterScreen()
      }
      .onAppear {
        containerWidth = geometry.size.width
      }
      .onChange(of: geometry.size.width) { _, newWidth in
        containerWidth = newWidth
        if isCounterListRevealed {
          cardOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(for: newWidth)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      Color.white
        .ignoresSafeArea()
    }
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
        selectedPageID = counter.id.uuidString
      }
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
        ForEach(Array(counters.enumerated()), id: \.element.id) { index, counter in
          CustomCounterPageContent(counter: counter, paletteIndex: index)
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

  private func openCounterList() {
    let width = max(containerWidth, 1)
    let maxOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(for: width)
    CounterUnderlayReveal<EmptyView, EmptyView>.lockRevealScrollForAnimation(
      $locksRevealScroll,
      reduceMotion: reduceMotion
    )
    withAnimation(settleSpring) {
      cardOffset = maxOffset
      isCounterListRevealed = true
    }
  }

  private func selectPageFromList(_ pageID: String) {
    if pageID != selectedPageID {
      withAnimation(.easeInOut(duration: 0.25)) {
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
    VStack(spacing: 0) {
      HStack(spacing: SpaceToken.x3) {
        CounterIconButton(icon: .listSortDescending) {
          openCounterList()
        }

        Text(activePageTitle)
          .counterTextStyle(.pageTitle)
          .lineLimit(1)

        Spacer(minLength: 0)

        HStack(spacing: SpaceToken.x3) {
          CounterIconButton(icon: .chartBar) {
            showHistory = true
          }

          CounterIconButton(icon: .slidersHorizontal) {
            showButtonSettings = true
          }
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
    .disabled(isPagerDragging)
  }

  @ViewBuilder
  private var buttonSettingsSheet: some View {
    if let counter = activeCounter {
      CounterSettingsView(
        title: "\(counter.name) Settings",
        values: counter.buttonValues,
        counter: counter
      ) { save in
        if let name = save.name {
          counter.name = name
        }
        counter.buttonValues = save.buttonValues
        counter.goal = save.goal
        counter.resetPeriod = save.resetPeriod
        counter.resetAnchorDay = save.resetAnchorDay
        counter.goalDirection = save.goalDirection
        WidgetSnapshotSync.publish(counter: counter, in: modelContext)
      }
    }
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
  }
}
