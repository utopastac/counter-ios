import SwiftUI

struct EntryLogPreviewItem: Identifiable, Equatable {
  let id: UUID
  let timestamp: Date
  let valueText: String
}

struct EntryLogAllEntriesControl: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: SpaceToken.x2) {
        Spacer(minLength: 0)

        Text("All entries")
          .counterTextStyle(.sectionTitle)

        Image(systemName: "arrow.up.left.and.arrow.down.right")
          .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
          .foregroundStyle(colors.textPrimary)
          .accessibilityHidden(true)
      }
      .padding(.bottom, SpaceToken.u2)

      Rectangle()
        .fill(colors.textPrimary)
        .frame(height: BorderToken.toolbar)
        .padding(.horizontal, SpaceToken.u1)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .contentShape(Rectangle())
  }
}

struct CompactEntryLogPreview: View {
  @Environment(\.semanticColors) private var colors

  let items: [EntryLogPreviewItem]
  let emptyMessage: String

  private var displayItems: [EntryLogPreviewItem] {
    Array(items.prefix(EntryLogPreviewLimit.count))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if displayItems.isEmpty {
        Text(emptyMessage)
          .counterTextStyle(.meta, color: .secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, SpaceToken.x3)
      } else {
        ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
          if index > 0 {
            Rectangle()
              .fill(colors.textPrimary)
              .frame(height: BorderToken.statsRow)
          }

          EntryLogPreviewRow(item: item)
            .padding(.vertical, SpaceToken.x3)
        }

        Rectangle()
          .fill(colors.textPrimary)
          .frame(height: BorderToken.statsRowStrong)
      }
    }
    .frame(maxWidth: .infinity, alignment: .bottomLeading)
  }
}

private struct EntryLogPreviewRow: View {
  let item: EntryLogPreviewItem

  var body: some View {
    HStack(spacing: SpaceToken.x3) {
      Text(item.valueText)
        .counterTextStyle(.rowHeavy)

      Spacer(minLength: 0)

      Text(item.timestamp, format: EntryLogPreviewRow.timestampFormat)
        .counterTextStyle(.meta, color: .secondary)
    }
  }

  private static let timestampFormat = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
    .hour(.defaultDigits(amPM: .abbreviated))
    .minute(.twoDigits)
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
