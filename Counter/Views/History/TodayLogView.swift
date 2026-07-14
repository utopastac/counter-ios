import SwiftUI
import SwiftData

// MARK: - Calorie log

struct CalorieTodayLogView: View {
  var body: some View {
    NavigationStack {
      CaloriePeriodEntryLogScreen()
    }
  }
}

struct CaloriePeriodEntryLogScreen: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(HealthKitManager.self) private var healthKit
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CalorieEntry.timestamp, order: .reverse) private var entries: [CalorieEntry]
  @Query private var settingsList: [AppSettings]

  @State private var editingEntry: EntryEditContext?

  private struct EntryEditContext: Identifiable {
    let id: UUID
    let value: Int
  }

  private var settings: AppSettings {
    settingsList.first ?? AppSettings()
  }

  private var periodEntries: [CalorieEntry] {
    let range = CounterPeriodCalculator.currentRange(for: settings)
    return CounterPeriodCalculator.calorieEntries(from: entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
  }

  private var periodTotal: Int {
    CounterPeriodCalculator.totalCalories(from: entries, for: settings)
  }

  var body: some View {
    CaloriePeriodEntryLogContent(
      entries: periodEntries,
      onDelete: deleteEntry,
      onEdit: { editingEntry = EntryEditContext(id: $0, value: $1) }
    )
    .navigationTitle(EntryLogTitles.full(for: settings.calorieResetPeriod))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .sheet(item: $editingEntry) { context in
      EditEntrySheet(initialValue: context.value) { newValue in
        updateEntry(id: context.id, value: newValue)
      }
    }
  }

  private func deleteEntry(id: UUID) {
    EntryActions.deleteCalorieEntry(id: id, in: modelContext)
    syncWidgetSnapshot()
  }

  private func updateEntry(id: UUID, value: Int) {
    EntryActions.updateCalorieEntry(id: id, value: value, in: modelContext)
    syncWidgetSnapshot()
  }

  private func syncWidgetSnapshot() {
    WidgetSnapshotSync.publish(from: modelContext, burned: Int(healthKit.activeCalories))
  }
}

struct CaloriePeriodEntryLogContent: View {
  let entries: [CalorieEntry]
  let onDelete: (UUID) -> Void
  let onEdit: (UUID, Int) -> Void

  var body: some View {
    Group {
      if entries.isEmpty {
        ContentUnavailableView(
          "No Entries Yet",
          systemImage: "list.bullet",
          description: Text("Entries for the current period will appear here.")
        )
      } else {
        List {
          ForEach(entries, id: \.id) { entry in
            Button {
              onEdit(entry.id, entry.value)
            } label: {
              TodayLogRow(
                timestamp: entry.timestamp,
                valueText: "\(entry.value) kcal"
              )
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                onDelete(entry.id)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
      }
    }
  }
}

// MARK: - Custom counter log

struct CounterTodayLogView: View {
  @Bindable var counter: CustomCounter

  var body: some View {
    NavigationStack {
      CounterPeriodEntryLogScreen(counter: counter)
    }
  }
}

struct CounterPeriodEntryLogScreen: View {
  @Bindable var counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var editingEntry: EntryEditContext?

  private struct EntryEditContext: Identifiable {
    let id: UUID
    let value: Int
  }

  private var periodEntries: [CounterEntry] {
    let range = CounterPeriodCalculator.currentRange(for: counter)
    return CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
  }

  var body: some View {
    CounterPeriodEntryLogContent(
      entries: periodEntries,
      onDelete: deleteEntry,
      onEdit: { editingEntry = EntryEditContext(id: $0, value: $1) }
    )
    .navigationTitle(EntryLogTitles.full(for: counter.resetPeriod))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .sheet(item: $editingEntry) { context in
      EditEntrySheet(initialValue: context.value) { newValue in
        updateEntry(id: context.id, value: newValue)
      }
    }
  }

  private func deleteEntry(id: UUID) {
    EntryActions.deleteCounterEntry(id: id, in: modelContext)
  }

  private func updateEntry(id: UUID, value: Int) {
    EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
  }
}

struct CounterPeriodEntryLogContent: View {
  let entries: [CounterEntry]
  let onDelete: (UUID) -> Void
  let onEdit: (UUID, Int) -> Void

  var body: some View {
    Group {
      if entries.isEmpty {
        ContentUnavailableView(
          "No Entries Yet",
          systemImage: "list.bullet",
          description: Text("Entries for the current period will appear here.")
        )
      } else {
        List {
          ForEach(entries, id: \.id) { entry in
            Button {
              onEdit(entry.id, entry.value)
            } label: {
              TodayLogRow(
                timestamp: entry.timestamp,
                valueText: "\(entry.value)"
              )
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                onDelete(entry.id)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
      }
    }
  }
}

// MARK: - Shared

enum EntryLogTitles {
  static func full(for period: CounterResetPeriod) -> String {
    switch period {
    case .daily: "Today's Log"
    case .weekly: "This Week's Log"
    case .monthly: "This Month's Log"
    }
  }

  static func preview(for period: CounterResetPeriod) -> String {
    switch period {
    case .daily: "Today"
    case .weekly: "This Week"
    case .monthly: "This Month"
    }
  }
}

struct TodayLogRow: View {
  let timestamp: Date
  let valueText: String

  var body: some View {
    HStack {
      Text(valueText)
        .fontWeight(.semibold)
        .monospacedDigit()
      Spacer()
      Text(timestamp, format: .dateTime.hour().minute())
        .foregroundStyle(.secondary)
    }
  }
}

struct EditEntrySheet: View {
  let initialValue: Int
  let onSave: (Int) -> Void

  var body: some View {
    AmountEntrySheet(
      title: "Edit",
      actionTitle: "Save",
      initialText: String(initialValue),
      onSubmit: onSave
    )
    .environment(\.counterAccent, nil)
    .counterDesignSystemFromColorScheme()
  }
}

#Preview {
  CalorieTodayLogView()
    .environment(HealthKitManager())
    .modelContainer(for: [CalorieEntry.self, AppSettings.self], inMemory: true)
}
