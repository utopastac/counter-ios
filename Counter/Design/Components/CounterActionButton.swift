import SwiftUI

struct CounterActionButton: View {
  @Environment(\.semanticColors) private var colors

  let label: String?
  let icon: CounterLucideIconName?
  let action: () -> Void

  init(_ label: String, action: @escaping () -> Void) {
    self.label = label
    self.icon = nil
    self.action = action
  }

  init(icon: CounterLucideIconName, action: @escaping () -> Void) {
    self.label = nil
    self.icon = icon
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Group {
        if let icon {
          CounterLucideIcon(icon: icon, color: colors.interactivePrimaryForeground)
        } else if let label {
          Text(label)
            .counterTextStyle(.button, color: .onInteractiveFill)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: SizeToken.quickAddHeight)
      .background(colors.interactivePrimaryFill, in: RoundedRectangle(cornerRadius: RadiusToken.sm, style: .continuous))
    }
    .buttonStyle(.plain)
    .tint(colors.interactivePrimaryForeground)
  }
}

struct CounterIconButton: View {
  @Environment(\.semanticColors) private var colors

  let icon: CounterLucideIconName
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      CounterLucideIcon(icon: icon, color: colors.textPrimary)
        .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
