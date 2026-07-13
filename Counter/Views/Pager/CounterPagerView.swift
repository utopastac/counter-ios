import SwiftUI
import SwiftData

struct CounterPagerView: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @Query private var settingsList: [AppSettings]

  @State private var selectedPageID: String? = PageID.calories.rawValue
  @State private var showButtonSettings = false
  @State private var showHistory = false
  @State private var showCalorieHistory = false
  @State private var showTodayLog = false
  @State private var showAddCounter = false
  @State private var isCounterListRevealed = false
  @State private var cardOffset: CGFloat = 0
  @State private var locksVerticalScroll = false
  @State private var containerWidth: CGFloat = 0

  enum PageID: String {
    case calories
  }

  private var pageIDs: [String] {
    [PageID.calories.rawValue] + counters.map(\.id.uuidString)
  }

  private var pageLabels: [String] {
    ["Calories"] + counters.map(\.name)
  }

  private var selectedIndex: Int {
    pageIDs.firstIndex(of: selectedPageID ?? PageID.calories.rawValue) ?? 0
  }

  private var isCaloriesPage: Bool {
    (selectedPageID ?? PageID.calories.rawValue) == PageID.calories.rawValue
  }

  private var activeCustomCounter: CustomCounter? {
    guard let selectedPageID else { return nil }
    return counters.first { $0.id.uuidString == selectedPageID }
  }

  private var settleSpring: Animation {
    if reduceMotion {
      return .easeOut(duration: 0.22)
    }
    return .smooth(duration: 0.48, extraBounce: 0.08)
  }

  var body: some View {
    GeometryReader { geometry in
      CounterUnderlayReveal(
        cardOffset: $cardOffset,
        isRevealed: $isCounterListRevealed,
        locksVerticalScroll: $locksVerticalScroll,
        listWidthFraction: 0.90
      ) {
        AllCountersListView(
          embedded: true,
          onSelectPage: selectPageFromList,
          onClose: collapseCounterList
        )
      } card: {
        counterScreen(height: geometry.size.height)
      }
      .onAppear {
        containerWidth = geometry.size.width
      }
      .onChange(of: geometry.size.width) { _, newWidth in
        containerWidth = newWidth
        if isCounterListRevealed {
          cardOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(
            for: newWidth,
            listWidthFraction: 0.90,
            maxScaleReduction: 0.14
          )
        }
      }
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
    .sheet(isPresented: $showTodayLog) {
      if isCaloriesPage {
        CalorieTodayLogView()
      } else if let counter = activeCustomCounter {
        CounterTodayLogView(counter: counter)
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
    }
  }

  @ViewBuilder
  private func counterScreen(height: CGFloat) -> some View {
    ZStack(alignment: .top) {
      verticalPager(height: height)

      pagerToolbar

      VStack {
        Spacer()
        PagerDotIndicator(labels: pageLabels, selectedIndex: selectedIndex)
      }
    }
    .background(Color.black)
  }

  @ViewBuilder
  private func verticalPager(height: CGFloat) -> some View {
    ScrollView(.vertical) {
      LazyVStack(spacing: 0) {
        CaloriesPageContent()
          .frame(height: height)
          .id(PageID.calories.rawValue)

        ForEach(counters) { counter in
          CustomCounterPageContent(counter: counter)
            .frame(height: height)
            .id(counter.id.uuidString)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $selectedPageID)
    .scrollIndicators(.hidden)
    .scrollDisabled(locksVerticalScroll)
    .animation(.easeInOut(duration: 0.25), value: selectedPageID)
    .animation(.easeInOut(duration: 0.25), value: counters.count)
  }

  private func openCounterList() {
    let width = max(containerWidth, 1)
    let maxOffset = CounterUnderlayReveal<EmptyView, EmptyView>.openOffset(
      for: width,
      listWidthFraction: 0.90,
      maxScaleReduction: 0.14
    )
    withAnimation(settleSpring) {
      cardOffset = maxOffset
      isCounterListRevealed = true
    }
  }

  private func selectPageFromList(_ pageID: String) {
    locksVerticalScroll = false
    selectedPageID = pageID
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
    HStack(spacing: 10) {
      Spacer()

      glassIconButton("square.grid.2x2") {
        openCounterList()
      }

      if isCaloriesPage {
        glassIconButton("arrow.clockwise") {
          Task { await healthKit.refreshToday() }
        }
      }

      glassIconButton("list.bullet") {
        showTodayLog = true
      }

      glassIconButton("chart.bar.xaxis") {
        if isCaloriesPage {
          showCalorieHistory = true
        } else {
          showHistory = true
        }
      }

      glassIconButton("slider.horizontal.3") {
        showButtonSettings = true
      }

      glassIconButton("plus") {
        showAddCounter = true
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
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

  private func glassIconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.body.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(.white.opacity(0.14), in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PreviewModel.appRoot {
    CounterPagerView()
  }
}
