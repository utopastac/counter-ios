import SwiftUI
import SwiftData

struct CustomCounterDetailView: View {
  @Bindable var counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var showButtonSettings = false
  @State private var showHistory = false

  private var periodTotal: Int {
    CounterPeriodCalculator.total(from: counter.entries, for: counter)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        StatCard(
          title: counter.resetPeriod.periodCaption.capitalized,
          value: heroValue,
          subtitle: counter.name,
          accent: .accentColor
        )

        QuickAddButtonsView(values: counter.buttonValues, unit: counter.name) { value in
          addEntryQuick(value)
        }
      }
      .padding()
    }
    .navigationTitle(counter.name)
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
    }
    .sheet(isPresented: $showButtonSettings) {
      CounterSettingsView(
        title: "\(counter.name) Settings",
        values: counter.buttonValues,
        counter: counter,
        onSave: { save in
          if let name = save.name {
            counter.name = name
          }
          counter.buttonValues = save.buttonValues
          counter.goal = save.goal
          counter.resetPeriod = save.resetPeriod
          counter.resetAnchorDay = save.resetAnchorDay
          counter.goalDirection = save.goalDirection
          if let paletteIndex = save.paletteIndex {
            counter.paletteIndex = paletteIndex
          }
          WidgetSnapshot.reloadTimelines()
        },
        onDelete: {
          modelContext.delete(counter)
          WidgetSnapshot.reloadTimelines()
          DispatchQueue.main.async {
            dismiss()
          }
        },
        onPaletteChange: { index in
          counter.paletteIndex = index
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
        }
      )
    }
    .sheet(isPresented: $showHistory) {
      CounterHistoryView(counter: counter)
    }
  }

  private var heroValue: String {
    GoalProgressCalculator.progress(
      current: periodTotal,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )?.heroValue ?? "\(periodTotal)"
  }

  private func addEntryQuick(_ value: Int) {
    EntryActions.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
  }
}

#Preview {
  NavigationStack {
    CustomCounterDetailView(counter: CustomCounter(name: "Protein"))
  }
  .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
