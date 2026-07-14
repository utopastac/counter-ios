import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  var embedded = false
  var scrollDisabled = false
  let onSelectPage: (String) -> Void
  var onClose: (() -> Void)?
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
          .navigationTitle("Counters")
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
    VStack(spacing: 0) {
      HStack {
        Text("Counters")
          .counterTextStyle(.pageTitle)
        Spacer()
        Button {
          close()
        } label: {
          CounterLucideIcon(icon: .chevronRight)
            .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, SpaceToken.pageMargin)
      .padding(.top, SpaceToken.toolbarTop)
      .padding(.bottom, SpaceToken.u2)

      ScrollView {
        listCards
          .padding(.horizontal, SpaceToken.pageMargin)
          .padding(.bottom, SpaceToken.componentPadding)
          .background {
            ScrollPanDisabler(isDisabled: scrollDisabled)
          }
      }
      .scrollDisabled(scrollDisabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color.white)
  }

  private var listCards: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u1) {
      ForEach(Array(counters.enumerated()), id: \.element.id) { index, counter in
        let total = CounterPeriodCalculator.total(from: counter.entries, for: counter)
        let ringProgress = GoalProgressCalculator.ringDisplay(
          current: total,
          goal: counter.effectiveGoal,
          direction: counter.goalDirection
        )
        let progress = GoalProgressCalculator.progress(
          current: total,
          goal: counter.effectiveGoal,
          direction: counter.goalDirection
        )

        CounterListCard(
          accent: .forCustomCounter(at: index),
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
    progress?.heroCaption.capitalized ?? counter.resetPeriod.periodCaption
  }

  private func close() {
    if embedded {
      onClose?()
    } else {
      dismiss()
    }
  }
}

#Preview {
  AllCountersListView { _ in }
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
