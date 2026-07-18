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

struct EntryLogPreviewTableDivider: View {
  var body: some View {
    SettingsDivider()
  }
}

struct EntryLogRowDivider: View {
  var body: some View {
    SettingsDivider()
  }
}

struct EntryLogRow: View {
  @Environment(\.semanticColors) private var colors

  let valueText: String
  let timestamp: Date
  var onDelete: (() -> Void)?

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      Text(valueText)
        .counterTextStyle(.entryLogValue)

      Spacer(minLength: 0)

      Text(timestamp, format: Self.timestampFormat)
        .counterTextStyle(.entryLogTimestamp)

      if let onDelete {
        Button(action: onDelete) {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(colors.textPrimary)
            .frame(width: SizeToken.iconGlyph, height: SizeToken.iconGlyph)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete entry")
      }
    }
  }

  static let timestampFormat = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
    .hour(.defaultDigits(amPM: .abbreviated))
    .minute(.twoDigits)
}

struct EntryLogEditableRow: View {
  let value: Double
  let timestamp: Date
  let onCommit: (Double) -> Void

  @State private var text: String
  @FocusState private var isFocused: Bool

  init(value: Double, timestamp: Date, onCommit: @escaping (Double) -> Void) {
    self.value = value
    self.timestamp = timestamp
    self.onCommit = onCommit
    _text = State(initialValue: CounterFormatting.editingText(for: value))
  }

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      TextField("", text: $text)
        .counterTextStyle(.entryLogValue)
        .textFieldStyle(.plain)
        .keyboardType(.numbersAndPunctuation)
        .focused($isFocused)
        .onChange(of: text) { _, newValue in
          let sanitized = AmountInput.sanitizedSignedDecimal(newValue, maxLength: 8)
          if sanitized != newValue {
            text = sanitized
          }
        }
        .onChange(of: value) { _, newValue in
          guard !isFocused else { return }
          text = CounterFormatting.editingText(for: newValue)
        }
        .onChange(of: isFocused) { _, focused in
          if !focused {
            commit()
          }
        }

      Spacer(minLength: 0)

      Text(timestamp, format: EntryLogRow.timestampFormat)
        .counterTextStyle(.entryLogTimestamp)
    }
  }

  private func commit() {
    guard let parsed = AmountInput.parseSignedAmount(text) else {
      text = CounterFormatting.editingText(for: value)
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
  var onDelete: ((UUID) -> Void)?

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

      if !displayItems.isEmpty {
        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
          VStack(spacing: 0) {
            if index > 0 {
              EntryLogRowDivider()
            }

            EntryLogRow(
              valueText: item.valueText,
              timestamp: item.timestamp,
              onDelete: onDelete.map { delete in { delete(item.id) } }
            )
              .frame(height: EntryLogToken.rowHeight)
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
