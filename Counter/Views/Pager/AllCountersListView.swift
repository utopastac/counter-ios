import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.semanticColors) private var colors
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  @State private var showAppSettings = false

  var scrollDisabled = false
  let transitionNamespace: Namespace.ID
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
    .sheet(isPresented: $showAppSettings) {
      AppSettingsView()
        .navigationTransition(.zoom(sourceID: SheetTransitionID.appSettings, in: transitionNamespace))
    }
    .counterDesignSystemFromColorScheme()
  }

  private var listHeader: some View {
    HStack {
      Spacer()
      HStack(spacing: SpaceToken.toolbarIconSpacing) {
        if let onAddCounter {
          CounterIconButton(icon: .plus, action: onAddCounter)
            .matchedTransitionSource(id: SheetTransitionID.addCounter, in: transitionNamespace)
        }
        CounterIconButton(icon: .cog) {
          showAppSettings = true
        }
        .matchedTransitionSource(id: SheetTransitionID.appSettings, in: transitionNamespace)
      }
    }
    .padding(.horizontal, SpaceToken.pageMargin)
    .padding(.top, SpaceToken.toolbarTop)
    .padding(.bottom, SpaceToken.u2)
    .background(colors.surfacePrimary)
  }

  private var listCards: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u1) {
      ForEach(counters) { counter in
        let total = counter.currentTotal()
        let progress = counter.currentProgress()

        CounterListCard(
          accent: .forCounter(counter),
          title: counter.name,
          value: cardValue(for: progress, total: total),
          caption: cardCaption(for: progress, counter: counter),
          ringProgress: progress
        ) {
          onSelectPage(counter.id.uuidString)
        }
      }

      if let onAddCounter {
        NewCounterButton(action: onAddCounter)
      }
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
  AllCountersListViewPreviewContainer()
}

private struct AllCountersListViewPreviewContainer: View {
  @Namespace private var transitionNamespace

  var body: some View {
    AllCountersListView(transitionNamespace: transitionNamespace) { _ in }
      .modelContainer(for: CustomCounter.self, inMemory: true)
  }
}
