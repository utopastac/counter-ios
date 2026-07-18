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

  private var periodEntries: [CounterEntry] {
    CounterPeriodCalculator.currentEntries(for: counter)
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
        onValueCommit: updateEntry
      )
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromColorScheme()
  }

  private func deleteEntry(id: UUID) {
    EntryActions.deleteCounterEntry(id: id, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }

  private func updateEntry(id: UUID, value: Double) {
    EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
  }
}

struct CounterPeriodEntryLogContent: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let entries: [CounterEntry]
  let emptyDescription: String
  let onDelete: (UUID) -> Void
  let onValueCommit: (UUID, Double) -> Void

  init(
    entries: [CounterEntry],
    emptyDescription: String = "Entries for the current period will appear here.",
    onDelete: @escaping (UUID) -> Void,
    onValueCommit: @escaping (UUID, Double) -> Void
  ) {
    self.entries = entries
    self.emptyDescription = emptyDescription
    self.onDelete = onDelete
    self.onValueCommit = onValueCommit
  }

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
          description: Text(emptyDescription)
        )
      } else {
        List {
          ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
            VStack(spacing: 0) {
              if index > 0 {
                EntryLogRowDivider()
                  .padding(.horizontal, SheetToken.horizontal)
              }

              EntryLogEditableRow(value: entry.amount, timestamp: entry.timestamp) { newValue in
                onValueCommit(entry.id, newValue)
              }
              .frame(height: SheetToken.tableRowHeight)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, SheetToken.horizontal)
            }
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

#Preview {
  CounterTodayLogView(counter: CustomCounter(name: "Calories"))
    .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
