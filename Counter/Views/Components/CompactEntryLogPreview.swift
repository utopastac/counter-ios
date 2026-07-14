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
