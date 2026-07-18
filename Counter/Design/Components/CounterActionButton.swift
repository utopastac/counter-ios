import SwiftUI

struct CounterActionButton: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  let label: String?
  let icon: CounterLucideIconName?
  let height: CGFloat
  let action: () -> Void

  init(_ label: String, height: CGFloat = SizeToken.quickAddHeight, action: @escaping () -> Void) {
    self.label = label
    self.icon = nil
    self.height = height
    self.action = action
  }

  init(icon: CounterLucideIconName, height: CGFloat = SizeToken.quickAddHeight, action: @escaping () -> Void) {
    self.label = nil
    self.icon = icon
    self.height = height
    self.action = action
  }

  var body: some View {
    Button {
      guard !counterRevealIsDragging else { return }
      action()
    } label: {
      Group {
        if let icon {
          CounterLucideIcon(icon: icon, color: colors.interactivePrimaryForeground)
        } else if let label {
          Text(label)
            .counterTextStyle(.button, color: .onInteractiveFill)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: height)
      .background(colors.interactivePrimaryFill, in: RadiusToken.continuousButton)
    }
    .buttonStyle(.plain)
    .tint(colors.interactivePrimaryForeground)
  }
}

struct CounterIconButton: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  let icon: CounterLucideIconName
  let action: () -> Void

  var body: some View {
    Button {
      guard !counterRevealIsDragging else { return }
      action()
    } label: {
      CounterLucideIcon(icon: icon, color: colors.textPrimary)
        .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
        .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
        .contentShape(Rectangle())
    }
    .buttonStyle(.icon)
  }
}

struct NewCounterButton: View {
  @Environment(\.semanticColors) private var colors

  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text("Add new")
          .counterTextStyle(.sectionTitle)

        Spacer(minLength: SpaceToken.u1)

        CounterLucideIcon(icon: .plus, color: colors.textPrimary)
      }
      .padding(.horizontal, SpaceToken.u2)
      .frame(maxWidth: .infinity)
      .frame(height: SizeToken.quickAddHeight)
      .background(ComponentColor.listActionButtonFill(colors), in: RadiusToken.continuousButton)
    }
    .buttonStyle(.plain)
  }
}
