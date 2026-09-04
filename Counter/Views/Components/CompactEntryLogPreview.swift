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
      Text("Entries")
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

enum EntryLogRowFormat {
  static let timestamp = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
    .hour(.defaultDigits(amPM: .abbreviated))
    .minute(.twoDigits)
}

struct EntryLogRow: View {
  @Environment(\.semanticColors) private var colors

  let valueText: String
  let timestamp: Date
  var onDelete: (() -> Void)?

  var body: some View {
    CounterValueDateRow(
      valueText: valueText,
      date: timestamp,
      dateFormat: EntryLogRowFormat.timestamp,
      trailing: {
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
    )
  }
}

struct EntryLogEditableRow: View {
  let value: Double
  let timestamp: Date
  var dateFormat: Date.FormatStyle = EntryLogRowFormat.timestamp
  let onEdit: () -> Void

  var body: some View {
    CounterValueDateRow(
      valueText: CounterFormatting.amount(value),
      date: timestamp,
      dateFormat: dateFormat,
      onTap: onEdit
    )
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
              .transition(rowTransition)
          }
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
