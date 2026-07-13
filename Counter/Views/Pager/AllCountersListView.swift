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
              .font(.headline)
            Spacer()
            Button {
              close()
            } label: {
              Image(systemName: "chevron.compact.right")
                .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)
          }
          .padding(.vertical, 4)
        }
      }

      Section {
        counterRow(
          title: "Calories",
          pageID: "calories",
          total: calorieTotal,
          progress: calorieGoalProgress,
          periodCaption: settings.calorieResetPeriod.periodCaption,
          suffix: "kcal"
        )

        ForEach(counters) { counter in
          let total = CounterPeriodCalculator.total(from: counter.entries, for: counter)
          counterRow(
            title: counter.name,
            pageID: counter.id.uuidString,
            total: total,
            progress: GoalProgressCalculator.progress(
              current: total,
              goal: counter.effectiveGoal,
              direction: counter.goalDirection
            ),
            periodCaption: counter.resetPeriod.periodCaption,
            suffix: nil
          )
        }
      }
    }
    .scrollContentBackground(.visible)
    .background(Color(.systemBackground))
  }

  @ViewBuilder
  private func counterRow(
    title: String,
    pageID: String,
    total: Int,
    progress: GoalProgress?,
    periodCaption: String,
    suffix: String?
  ) -> some View {
    Button {
      onSelectPage(pageID)
    } label: {
      HStack(spacing: 14) {
        if let progress {
          GoalProgressRing(progress: progress, size: 52, lineWidth: 6)
        } else {
          noGoalBadge(total: total, suffix: suffix)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)

          if let progress {
            Text(progress.listSubtitle + (suffix.map { " \($0)" } ?? ""))
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            Text(formattedTotal(total, suffix: suffix) + " · \(periodCaption)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer(minLength: 0)

        if let progress {
          VStack(alignment: .trailing, spacing: 2) {
            Text(progress.summaryValue + (suffix.map { " \($0)" } ?? ""))
              .font(.subheadline.weight(.semibold).monospacedDigit())
              .foregroundStyle(.primary)
            Text(progress.summaryCaption)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func noGoalBadge(total: Int, suffix: String?) -> some View {
    ZStack {
      Circle()
        .stroke(Color.secondary.opacity(0.25), lineWidth: 6)
      Text(formattedTotal(total, suffix: suffix))
        .font(.caption.weight(.semibold).monospacedDigit())
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(8)
    }
    .frame(width: 52, height: 52)
  }

  private func formattedTotal(_ total: Int, suffix: String?) -> String {
    if let suffix {
      return "\(total) \(suffix)"
    }
    return "\(total)"
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
