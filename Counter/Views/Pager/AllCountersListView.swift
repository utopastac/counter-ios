import SwiftUI
import SwiftData

struct AllCountersListView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var calorieEntries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  var embedded = false
  let onSelectPage: (String) -> Void
  var onClose: (() -> Void)?

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var calorieTotal: Int {
    CounterPeriodCalculator.totalCalories(from: calorieEntries, for: settings)
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
        listContent
      } else {
        NavigationStack {
          listContent
            .navigationTitle("All Counters")
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

  private var listContent: some View {
    List {
      if embedded {
        Section {
          HStack {
            Text("All Counters")
              .counterTextStyle(.headline)
            Spacer()
            Button {
              close()
            } label: {
              Image(systemName: "chevron.compact.right")
                .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)
          }
          .padding(.vertical, SpaceToken.x1)
        }
      }

      Section {
        CounterListRow(
          title: "Calories",
          total: calorieTotal,
          progress: calorieGoalProgress,
          periodCaption: settings.calorieResetPeriod.periodCaption,
          suffix: "kcal"
        ) {
          onSelectPage("calories")
        }

        ForEach(counters) { counter in
          let total = CounterPeriodCalculator.total(from: counter.entries, for: counter)
          CounterListRow(
            title: counter.name,
            total: total,
            progress: GoalProgressCalculator.progress(
              current: total,
              goal: counter.effectiveGoal,
              direction: counter.goalDirection
            ),
            periodCaption: counter.resetPeriod.periodCaption,
            suffix: nil
          ) {
            onSelectPage(counter.id.uuidString)
          }
        }
      }
    }
    .scrollContentBackground(.visible)
    .background(Color(.systemBackground))
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
