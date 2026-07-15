import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  @State private var showAppSettings = false

  var embedded = false
  var scrollDisabled = false
  let onSelectPage: (String) -> Void
  var onAddCounter: (() -> Void)?

  var body: some View {
    Group {
      if embedded {
        embeddedListContent
      } else {
        NavigationStack {
          ScrollView {
            listCards
              .padding(.horizontal, SpaceToken.pageMargin)
              .padding(.vertical, SpaceToken.componentPadding)
          }
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                dismiss()
              }
            }
          }
        }
      }
    }
  }

  private var embeddedListContent: some View {
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
    }
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
          showAppSettings = true
        }
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
        let ringProgress = counter.currentRingDisplay()
        let progress = counter.currentProgress()

        CounterListCard(
          accent: .forCounter(counter),
          title: counter.name,
          value: cardValue(for: progress, total: total),
          caption: cardCaption(for: progress, counter: counter),
          ringProgress: ringProgress
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
  AllCountersListView { _ in }
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
