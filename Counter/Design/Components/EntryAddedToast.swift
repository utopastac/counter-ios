import SwiftUI

struct EntryAddedToast: View {
  @Environment(\.semanticColors) private var colors

  let value: Int
  let onUndo: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      Text("\(value) added")
        .counterTextStyle(.button, color: .onInteractiveFill, compact: true)
        .padding(.horizontal, SpaceToken.u2)

      Rectangle()
        .fill(colors.interactivePrimaryForeground.opacity(0.35))
        .frame(width: 1, height: SizeToken.iconGlyph)

      Button(action: onUndo) {
        CounterLucideIcon(icon: .undo2, color: colors.interactivePrimaryForeground)
          .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
          .padding(.horizontal, SpaceToken.u2)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Undo")
    }
    .padding(.vertical, SpaceToken.u1)
    .background(colors.interactivePrimaryFill, in: RadiusToken.continuousButton)
    .fixedSize()
    .accessibilityElement(children: .contain)
  }
}

struct EntryToastState: Equatable {
  let entryID: UUID
  let value: Int
}
