import SwiftUI
import SwiftData

struct CalorieTodayLogView: View {
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

  private var logTitle: String {
    switch settings.calorieResetPeriod {
    case .daily: "Today's Log"
    case .weekly: "This Week's Log"
    case .monthly: "This Month's Log"
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if periodEntries.isEmpty {
          ContentUnavailableView(
            "No Entries Yet",
            systemImage: "list.bullet",
            description: Text("Entries for the current period will appear here.")
          )
        } else {
          List {
            ForEach(periodEntries, id: \.id) { entry in
              TodayLogRow(
                timestamp: entry.timestamp,
                valueText: "\(entry.value) kcal"
              )
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                  deleteEntry(id: entry.id)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                  editingEntry = EntryEditContext(
                    id: entry.id,
                    value: entry.value
                  )
                } label: {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
              }
            }
          }
        }
      }
      .navigationTitle(logTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet(item: $editingEntry) { context in
        EditEntrySheet(
          title: "Edit Entry",
          initialValue: context.value
        ) { newValue in
          updateEntry(id: context.id, value: newValue)
        }
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
    WidgetSnapshot.publish(added: periodTotal, burned: Int(healthKit.activeCalories))
  }
}

struct CounterTodayLogView: View {
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

  private var logTitle: String {
    switch counter.resetPeriod {
    case .daily: "Today's Log"
    case .weekly: "This Week's Log"
    case .monthly: "This Month's Log"
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if periodEntries.isEmpty {
          ContentUnavailableView(
            "No Entries Yet",
            systemImage: "list.bullet",
            description: Text("Entries for the current period will appear here.")
          )
        } else {
          List {
            ForEach(periodEntries, id: \.id) { entry in
              TodayLogRow(
                timestamp: entry.timestamp,
                valueText: "\(entry.value)"
              )
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                  deleteEntry(id: entry.id)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                  editingEntry = EntryEditContext(
                    id: entry.id,
                    value: entry.value
                  )
                } label: {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
              }
            }
          }
        }
      }
      .navigationTitle(logTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet(item: $editingEntry) { context in
        EditEntrySheet(
          title: "Edit Entry",
          initialValue: context.value
        ) { newValue in
          updateEntry(id: context.id, value: newValue)
        }
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

private struct TodayLogRow: View {
  let timestamp: Date
  let valueText: String

  var body: some View {
    HStack {
      Text(timestamp, format: .dateTime.hour().minute())
      Spacer()
      Text(valueText)
        .fontWeight(.semibold)
        .monospacedDigit()
    }
  }
}

struct EditEntrySheet: View {
  @Environment(\.dismiss) private var dismiss

  let title: String
  let initialValue: Int
  let onSave: (Int) -> Void

  @State private var valueText: String

  init(
    title: String,
    initialValue: Int,
    onSave: @escaping (Int) -> Void
  ) {
    self.title = title
    self.initialValue = initialValue
    self.onSave = onSave
    _valueText = State(initialValue: String(initialValue))
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Amount", text: $valueText)
          .keyboardType(.numberPad)
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            guard let value = parsedValue else { return }
            onSave(value)
            dismiss()
          }
          .disabled(parsedValue == nil)
        }
      }
    }
    .presentationDetents([.medium])
  }

  private var parsedValue: Int? {
    guard let value = Int(valueText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }
}

#Preview {
  CalorieTodayLogView()
    .environment(HealthKitManager())
    .modelContainer(for: [CalorieEntry.self, AppSettings.self], inMemory: true)
}
