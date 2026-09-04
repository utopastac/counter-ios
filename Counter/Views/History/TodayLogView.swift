import SwiftUI
import SwiftData

/// Editable entry list used by history bucket sheets (hour / day / week taps).
struct CounterPeriodEntryLogContent: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let entries: [CounterEntry]
  let emptyDescription: String
  let onDelete: (UUID) -> Void
  let onValueCommit: (UUID, Double) -> Void

  @State private var editingEntry: EditingEntry?

  init(
    entries: [CounterEntry],
    emptyDescription: String = "No entries in this period.",
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

              EntryLogEditableRow(
                value: entry.amount,
                timestamp: entry.timestamp,
                onEdit: {
                  editingEntry = EditingEntry(id: entry.id, value: entry.amount)
                }
              )
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
    .sheet(item: $editingEntry) { entry in
      EditAmountSheet(initialValue: entry.value) { newValue in
        onValueCommit(entry.id, newValue)
      }
    }
  }
}

private struct EditingEntry: Identifiable, Equatable {
  let id: UUID
  let value: Double
}
