import SwiftUI
import UIKit

/// Dismisses the system keyboard without delaying the caller's action.
enum CounterKeyboard {
  @MainActor
  static func resign() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }
}

struct CounterSheetHeader: View {
  let title: String
  let trailingTitle: String
  let isDoneEnabled: Bool
  let onDone: () -> Void

  init(
    title: String,
    trailingTitle: String = "Done",
    isDoneEnabled: Bool = true,
    onDone: @escaping () -> Void
  ) {
    self.title = title
    self.trailingTitle = trailingTitle
    self.isDoneEnabled = isDoneEnabled
    self.onDone = onDone
  }

  var body: some View {
    HStack(alignment: .center) {
      Text(title)
        .counterTextStyle(.sheetTitle)

      Spacer(minLength: SpaceToken.u1)

      Button(trailingTitle) {
        CounterKeyboard.resign()
        onDone()
      }
      .counterTextStyle(.settingsRowLabel, color: isDoneEnabled ? .primary : .disabled)
      .buttonStyle(.plain)
      .disabled(!isDoneEnabled)
    }
    .padding(.horizontal, SheetToken.horizontal)
    .padding(.top, SpaceToken.u2)
    .padding(.bottom, SpaceToken.u1)
  }
}

#Preview {
  CounterSheetHeader(title: "Calories history") {}
    .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}

struct SettingsDivider: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    Rectangle()
      .fill(ComponentColor.settingsDividerFill(colors))
      .frame(height: BorderToken.settingsDivider)
  }
}

struct SettingsDestructiveRow: View {
  @Environment(\.semanticColors) private var colors

  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: SpaceToken.u2) {
        Text(label)
          .counterTextStyle(.settingsRowLabel, color: .danger)

        Spacer(minLength: SpaceToken.u1)
      }
      .frame(minHeight: SizeToken.quickAddHeight)
      .contentShape(Rectangle())
    }
    .buttonStyle(.scrollSafe)
    .tint(colors.statusDanger)
  }
}
