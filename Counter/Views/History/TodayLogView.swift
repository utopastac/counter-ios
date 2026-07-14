import SwiftUI
import SwiftData

// MARK: - Custom counter log

struct CounterTodayLogView: View {
  @Bindable var counter: CustomCounter

  var body: some View {
    CounterPeriodEntryLogScreen(counter: counter)
      .counterSheetPresentation()
  }
}

struct CounterPeriodEntryLogScreen: View {
  @Bindable var counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.semanticColors) private var colors

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
    VStack(spacing: 0) {
      CounterSheetHeader(
        title: "\(counter.name) entries",
        onDone: { dismiss() }
      )

      CounterPeriodEntryLogContent(
        entries: periodEntries,
        onDelete: deleteEntry,
        onEdit: { editingEntry = EntryEditContext(id: $0, value: $1) }
      )
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromColorScheme()
    .sheet(item: $editingEntry) { context in
      EditEntrySheet(initialValue: context.value) { newValue in
        updateEntry(id: context.id, value: newValue)
      }
    }
  }

  private func deleteEntry(id: UUID) {
    EntryActions.deleteCounterEntry(id: id, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }

  private func updateEntry(id: UUID, value: Int) {
    EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}

struct CounterPeriodEntryLogContent: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let entries: [CounterEntry]
  let onDelete: (UUID) -> Void
  let onEdit: (UUID, Int) -> Void

  private var insertAnimation: Animation {
    MotionToken.entryInsert(reduceMotion: reduceMotion)
  }

  private var rowTransition: AnyTransition {
    MotionToken.entryRowTransition(reduceMotion: reduceMotion)
  }

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
          ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
            Button {
              onEdit(entry.id, entry.value)
            } label: {
              VStack(spacing: 0) {
                if index > 0 {
                  EntryLogRowDivider()
                }

                EntryLogRow(valueText: "\(entry.value)", timestamp: entry.timestamp)
                  .frame(height: SheetToken.tableRowHeight)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, SheetToken.horizontal)
              }
            }
            .buttonStyle(.noHighlight)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .transition(rowTransition)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                onDelete(entry.id)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
        .animation(insertAnimation, value: entries.map(\.id))
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
  CounterTodayLogView(counter: CustomCounter(name: "Calories"))
    .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
