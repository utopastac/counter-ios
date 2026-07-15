import SwiftUI

struct EntryLogPreviewItem: Identifiable, Equatable {
  let id: UUID
  let timestamp: Date
  let valueText: String
}

struct EntryLogAllEntriesControl: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    HStack(spacing: SpaceToken.x2) {
      Text("All entries")
        .counterTextStyle(.sectionTitle)

      CounterLucideIcon(icon: .maximize2, color: colors.textPrimary)
    }
    .padding(.top, SpaceToken.u2)
    .frame(maxWidth: .infinity, alignment: .center)
    .contentShape(Rectangle())
  }
}

struct EntryLogAllEntriesButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      EntryLogAllEntriesControl()
    }
    .buttonStyle(.noHighlight)
  }
}

struct EntryLogPreviewTableDivider: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    Rectangle()
      .fill(colors.textPrimary)
      .frame(height: BorderToken.toolbar)
  }
}

struct EntryLogRowDivider: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    Rectangle()
      .fill(colors.textPrimary)
      .frame(height: BorderToken.statsRow)
  }
}

struct EntryLogRow: View {
  let valueText: String
  let timestamp: Date

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      Text(valueText)
        .counterTextStyle(.rowHeavy)

      Spacer(minLength: 0)

      Text(timestamp, format: Self.timestampFormat)
        .counterTextStyle(.meta, color: .secondary)
    }
  }

  static let timestampFormat = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
    .hour(.defaultDigits(amPM: .abbreviated))
    .minute(.twoDigits)
}

struct EntryLogEditableRow: View {
  let value: Int
  let timestamp: Date
  let onCommit: (Int) -> Void

  @State private var text: String
  @FocusState private var isFocused: Bool

  init(value: Int, timestamp: Date, onCommit: @escaping (Int) -> Void) {
    self.value = value
    self.timestamp = timestamp
    self.onCommit = onCommit
    _text = State(initialValue: String(value))
  }

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      TextField("", text: $text)
        .counterTextStyle(.rowHeavy)
        .textFieldStyle(.plain)
        .keyboardType(.numbersAndPunctuation)
        .focused($isFocused)
        .onChange(of: text) { _, newValue in
          let sanitized = AmountInput.sanitizedSignedDigits(newValue, maxLength: 7)
          if sanitized != newValue {
            text = sanitized
          }
        }
        .onChange(of: value) { _, newValue in
          guard !isFocused else { return }
          text = String(newValue)
        }
        .onChange(of: isFocused) { _, focused in
          if !focused {
            commit()
          }
        }

      Spacer(minLength: 0)

      Text(timestamp, format: EntryLogRow.timestampFormat)
        .counterTextStyle(.meta, color: .secondary)
    }
  }

  private func commit() {
    guard let parsed = Int(text) else {
      text = String(value)
      return
    }

    guard parsed != value else { return }
    onCommit(parsed)
  }
}

struct CompactEntryLogPreview: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let items: [EntryLogPreviewItem]
  let emptyMessage: String

  private var displayItems: [EntryLogPreviewItem] {
    Array(items.prefix(EntryLogPreviewLimit.count))
  }

  private var insertAnimation: Animation {
    MotionToken.entryInsert(reduceMotion: reduceMotion)
  }

  private var rowTransition: AnyTransition {
    MotionToken.entryRowTransition(reduceMotion: reduceMotion)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      EntryLogPreviewTableDivider()

      if displayItems.isEmpty {
        Text(emptyMessage)
          .counterTextStyle(.meta, color: .secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(height: SizeToken.tableRowHeight)
          .contentShape(Rectangle())
          .transition(.opacity)
      } else {
        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
          VStack(spacing: 0) {
            if index > 0 {
              EntryLogRowDivider()
            }

            EntryLogRow(valueText: item.valueText, timestamp: item.timestamp)
              .frame(height: SizeToken.tableRowHeight)
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
          }
          .transition(rowTransition)
        }

        Rectangle()
          .fill(colors.textPrimary)
          .frame(height: BorderToken.statsRowStrong)
      }
    }
    .frame(maxWidth: .infinity, alignment: .bottomLeading)
    .animation(insertAnimation, value: displayItems)
    .clipped()
  }
}

struct BottomFadeMask: View {
  var fadeHeight: CGFloat = 52

  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
      LinearGradient(
        colors: [.black, .black.opacity(0)],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: fadeHeight)
    }
  }
}
