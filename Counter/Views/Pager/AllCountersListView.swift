import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var calorieEntries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  var embedded = false
  let onSelectPage: (String) -> Void
  var onClose: (() -> Void)?
  var onAddCounter: (() -> Void)?

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var calorieTotal: Int {
    CounterPeriodCalculator.totalCalories(from: calorieEntries, for: settings)
  }

  private var calorieRingProgress: GoalProgress {
    GoalProgressCalculator.ringDisplay(
      current: calorieTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
  }

  private var calorieGoalProgress: GoalProgress? {
    GoalProgressCalculator.progress(
      current: calorieTotal,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
  }

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
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color.white)
  }

  private var listCards: some View {
    VStack(alignment: .leading, spacing: SpaceToken.x4) {
      CounterListCard(
        accent: .calories,
        title: "Calories",
        value: calorieSummaryValue,
        caption: calorieSummaryCaption,
        ringProgress: calorieRingProgress
      ) {
        onSelectPage("calories")
      }

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
        Button(action: onAddCounter) {
          HStack(spacing: SpaceToken.x2) {
            CounterLucideIcon(icon: .plus)
            Text("New counter")
              .counterTextStyle(.rowLight)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, SpaceToken.componentPadding)
          .background(
            SemanticColors.forColorScheme(colorScheme).surfaceGlassFillSubtle,
            in: RadiusToken.continuousListCard
          )
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var calorieSummaryValue: String {
    calorieGoalProgress?.heroValue ?? "\(calorieTotal)"
  }

  private var calorieSummaryCaption: String {
    calorieGoalProgress?.heroCaption.capitalized ?? settings.calorieResetPeriod.periodCaption
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
    .modelContainer(for: [CustomCounter.self, CalorieEntry.self, AppSettings.self], inMemory: true)
}
