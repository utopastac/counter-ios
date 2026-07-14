import SwiftUI
import SwiftData

struct CalorieCounterView: View {
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var entries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  @State private var showButtonSettings = false
  @State private var showHistory = false
  @State private var buttonValues: [Int] = AppSettings().calorieButtonValues

  private var netCalories: Double {
    Double(periodTotal) - healthKit.activeCalories
  }

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var periodTotal: Int {
    CounterPeriodCalculator.totalCalories(from: entries, for: settings)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          weightSection
          burnedSection
          consumedSection
          netSection
          QuickAddButtonsView(values: buttonValues, unit: "kcal") { value in
            addCaloriesQuick(value)
          }
        }
        .padding()
      }
      .navigationTitle("Calories")
      .onAppear {
        ensureSettings()
        syncWidgetSnapshot()
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showHistory = true
          } label: {
            Label("History", systemImage: "chart.bar.xaxis")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showButtonSettings = true
          } label: {
            Label("Edit Buttons", systemImage: "slider.horizontal.3")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await healthKit.refreshToday() }
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
        }
      }
      .sheet(isPresented: $showButtonSettings) {
        CounterSettingsView(
          title: "Calorie Settings",
          values: buttonValues,
          settings: settings
        ) { save in
          buttonValues = save.buttonValues
          if let settings = settingsList.first {
            settings.calorieButtonValues = save.buttonValues
            settings.calorieGoal = save.goal
            settings.calorieResetPeriod = save.resetPeriod
            settings.calorieResetAnchorDay = save.resetAnchorDay
            settings.calorieGoalDirection = .countDown
          }
        }
      }
      .sheet(isPresented: $showHistory) {
        CalorieHistoryView()
      }
      .refreshable {
        await healthKit.refreshToday()
        syncWidgetSnapshot()
      }
    }
  }

  private var weightSection: some View {
    Group {
      if let weight = healthKit.weightKg {
        StatCard(
          title: "Weight",
          value: String(format: "%.1f kg", weight),
          subtitle: "From Apple Health"
        )
      }
    }
  }

  private var burnedSection: some View {
    VStack(spacing: 12) {
      Text("Active Calories Burned")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)

      StatCard(
        title: "Active",
        value: "\(Int(healthKit.activeCalories))",
        subtitle: "kcal from Apple Health",
        accent: .orange
      )
    }
  }

  private var consumedSection: some View {
    StatCard(
      title: "Calories Added",
      value: "\(periodTotal)",
      subtitle: "tap buttons to log food",
      accent: .green
    )
  }

  private var netSection: some View {
    let isSurplus = netCalories > 0
    return StatCard(
      title: "Net Today",
      value: String(format: "%+.0f", netCalories),
      subtitle: isSurplus ? "surplus (added > burned)" : "deficit (burned > added)",
      accent: isSurplus ? .red : .mint
    )
  }

  private func addCaloriesQuick(_ value: Int) {
    EntryActions.addCalorieQuick(value: value, in: modelContext)
    syncWidgetSnapshot()
  }

  private func syncWidgetSnapshot() {
    WidgetSnapshotSync.publish(from: modelContext, burned: Int(healthKit.activeCalories))
  }

  private func ensureSettings() {
    if let settings = settingsList.first {
      buttonValues = settings.calorieButtonValues
    } else {
      let created = AppSettings()
      modelContext.insert(created)
      buttonValues = created.calorieButtonValues
    }
  }
}

#Preview {
  PreviewModel.appRoot {
    CalorieCounterView()
  }
}
