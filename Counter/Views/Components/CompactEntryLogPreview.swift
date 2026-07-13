import SwiftUI

struct EntryLogPreviewItem: Identifiable, Equatable {
  let id: UUID
  let timestamp: Date
  let valueText: String
}

struct CompactEntryLogPreview: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  let items: [EntryLogPreviewItem]
  let emptyMessage: String

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.x2) {
      HStack {
        SectionLabel(title: title)
        Spacer()
        Image(systemName: "arrow.up.left.and.arrow.down.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(colors.textSecondary)
      }

      if items.isEmpty {
        Text(emptyMessage)
          .counterTextStyle(.caption, color: .secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, SpaceToken.x3)
      } else {
        VStack(spacing: SpaceToken.x2) {
          ForEach(items) { item in
            EntryLogPreviewRow(item: item)
          }
        }
      }
    }
    .padding(.horizontal, SpaceToken.x4)
    .padding(.vertical, SpaceToken.x3)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(colors.surfaceGlassFillSubtle, in: RoundedRectangle(cornerRadius: RadiusToken.lg, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: RadiusToken.lg, style: .continuous)
        .strokeBorder(colors.surfaceGlassStroke, lineWidth: 1)
    }
  }
}

private struct EntryLogPreviewRow: View {
  @Environment(\.semanticColors) private var colors

  let item: EntryLogPreviewItem

  var body: some View {
    HStack(spacing: SpaceToken.x3) {
      Text(item.valueText)
        .counterTextStyle(.subheadlineSemibold, color: .primary)
      Spacer(minLength: 0)
      Text(item.timestamp, format: .dateTime.hour().minute())
        .counterTextStyle(.caption, color: .secondary)
    }
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
