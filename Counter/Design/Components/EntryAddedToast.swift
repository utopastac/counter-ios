import SwiftUI

struct EntryAddedToast: View {
  @Environment(\.semanticColors) private var colors

  let value: Double
  var kind: EntryToastState.Kind = .added
  let onUndo: () -> Void

  private var message: String {
    let amount = CounterFormatting.amount(value)
    switch kind {
    case .added:
      return "\(amount) added"
    case .removed:
      return "\(amount) removed"
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      Text(message)
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
  enum Kind: Equatable {
    case added
    case removed(timestamp: Date)
  }

  let entryID: UUID
  let value: Double
  let kind: Kind

  init(entryID: UUID, value: Double, kind: Kind = .added) {
    self.entryID = entryID
    self.value = value
    self.kind = kind
  }
}
