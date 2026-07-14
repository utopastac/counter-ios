import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @Query private var settingsList: [AppSettings]

  @State private var selectedPageID: String? = PageID.calories.rawValue
  @State private var showButtonSettings = false
  @State private var showHistory = false
  @State private var showCalorieHistory = false
  @State private var showAddCounter = false
  @State private var isCounterListRevealed = false
  @State private var cardOffset: CGFloat = 0
  @State private var locksRevealScroll = false
  @State private var containerWidth: CGFloat = 0
  @State private var scrollProgress: CGFloat = 0

  enum PageID: String {
    case calories
  }

  private var pageIDs: [String] {
    [PageID.calories.rawValue] + counters.map(\.id.uuidString)
  }

  private var isCaloriesPage: Bool {
    (selectedPageID ?? PageID.calories.rawValue) == PageID.calories.rawValue
  }

  private var activeCustomCounter: CustomCounter? {
    guard let selectedPageID else { return nil }
    return counters.first { $0.id.uuidString == selectedPageID }
  }

  private var pageAccents: [CounterAccent] {
    [.calories] + counters.enumerated().map { CounterAccent.forCustomCounter(at: $0.offset) }
  }

  private var activeAccent: CounterAccent {
    if isCaloriesPage { return .calories }
    if let counter = activeCustomCounter,
       let index = counters.firstIndex(where: { $0.id == counter.id }) {
      return .forCustomCounter(at: index)
    }
    return .calories
  }

  private var activePageTitle: String {
    if isCaloriesPage { return "Calories" }
    return activeCustomCounter?.name ?? "Counter"
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

  private var isRevealInTransition: Bool {
    let maxOffset = maxRevealOffset
    guard maxOffset > 0 else { return false }
    return cardOffset > 1 && cardOffset < maxOffset - 1
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
    .sheet(isPresented: $showCalorieHistory) {
      CalorieHistoryView()
    }
    .sheet(isPresented: $showHistory) {
      if let counter = activeCustomCounter {
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
        self.selectedPageID = PageID.calories.rawValue
      }
      syncScrollProgressToSelectedPage()
    }
    .onAppear {
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
  }

  @ViewBuilder
  private func verticalPager(height: CGFloat) -> some View {
    ScrollView(.vertical) {
      VStack(spacing: 0) {
        CaloriesPageContent()
          .frame(height: height)
          .background(Color.clear)
          .id(PageID.calories.rawValue)

        ForEach(Array(counters.enumerated()), id: \.element.id) { index, counter in
          CustomCounterPageContent(counter: counter, paletteIndex: index)
            .frame(height: height)
            .background(Color.clear)
            .id(counter.id.uuidString)
        }
      }
      .scrollTargetLayout()
      .counterPagerBackground(accents: pageAccents, scrollProgress: scrollProgress)
    }
    .scrollContentBackground(.hidden)
    .background(Color.clear)
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $selectedPageID, anchor: .top)
    .scrollIndicators(.hidden)
    .scrollDisabled(locksRevealScroll || isRevealInTransition)
    .scrollClipDisabled()
    .onScrollGeometryChange(for: CGFloat.self) { geometry in
      geometry.contentOffset.y + geometry.contentInsets.top
    } action: { _, offset in
      guard height > 0 else { return }
      scrollProgress = offset / height
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
            if isCaloriesPage {
              showCalorieHistory = true
            } else {
              showHistory = true
            }
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
  }

  @ViewBuilder
  private var buttonSettingsSheet: some View {
    if isCaloriesPage {
      if let settings = settingsList.first {
        CounterSettingsView(
          title: "Calorie Settings",
          values: settings.calorieButtonValues,
          settings: settings
        ) { save in
          settings.calorieButtonValues = save.buttonValues
          settings.calorieGoal = save.goal
          settings.calorieResetPeriod = save.resetPeriod
          settings.calorieResetAnchorDay = save.resetAnchorDay
          settings.calorieGoalDirection = .countDown
        }
      } else {
        CounterSettingsView(
          title: "Calorie Settings",
          values: AppSettings().calorieButtonValues,
          settings: AppSettings()
        ) { save in
          let created = AppSettings(
            calorieButtonValues: save.buttonValues,
            calorieGoal: save.goal,
            calorieResetPeriod: save.resetPeriod,
            calorieResetAnchorDay: save.resetAnchorDay,
            calorieGoalDirection: .countDown
          )
          modelContext.insert(created)
        }
      }
    } else if let counter = activeCustomCounter {
      CounterSettingsView(
        title: "\(counter.name) Settings",
        values: counter.buttonValues,
        counter: counter
      ) { save in
        counter.buttonValues = save.buttonValues
        counter.goal = save.goal
        counter.resetPeriod = save.resetPeriod
        counter.resetAnchorDay = save.resetAnchorDay
        counter.goalDirection = save.goalDirection
      }
    }
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
  }
}
