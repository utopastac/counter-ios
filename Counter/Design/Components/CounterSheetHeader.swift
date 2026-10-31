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
  /// Primary trailing action (Save / Keep / Add). Dismiss-only sheets omit this and use swipe-to-dismiss.
  var trailingTitle: String? = nil
  var isTrailingEnabled: Bool = true
  var onTrailing: (() -> Void)? = nil
  /// 0 = fully expanded large title, 1 = fully collapsed into the sticky compact title.
  var collapseProgress: CGFloat = 0

  init(title: String, collapseProgress: CGFloat = 0) {
    self.title = title
    self.collapseProgress = collapseProgress
  }

  init(
    title: String,
    trailingTitle: String,
    isDoneEnabled: Bool = true,
    onDone: @escaping () -> Void
  ) {
    self.title = title
    self.trailingTitle = trailingTitle
    self.isTrailingEnabled = isDoneEnabled
    self.onTrailing = onDone
  }

  var body: some View {
    HStack(alignment: .center) {
      Text(title)
        .counterTextStyle(.sheetTitle)
        // Keep layout size stable while fading so collapse progress stays predictable.
        .opacity(1 - collapseProgress)

      Spacer(minLength: SpaceToken.u1)

      if let trailingTitle, let onTrailing {
        Button(trailingTitle) {
          CounterKeyboard.resign()
          onTrailing()
        }
        .counterTextStyle(.settingsRowLabel, color: isTrailingEnabled ? .primary : .disabled)
        .buttonStyle(.plain)
        .disabled(!isTrailingEnabled)
        .accessibilityIdentifier("sheet-dismiss")
        .accessibilityLabel(trailingTitle)
      }
    }
    .padding(.horizontal, SheetToken.horizontal)
    .padding(.top, SpaceToken.u4)
    .padding(.bottom, SpaceToken.u1)
    .accessibilityHidden(collapseProgress > 0.85)
  }
}

/// Compact sticky title that crossfades in as the large sheet title collapses.
struct CounterSheetStickyTitle: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  var collapseProgress: CGFloat = 0
  var trailingTitle: String? = nil
  var isTrailingEnabled: Bool = true
  var onTrailing: (() -> Void)? = nil

  var body: some View {
    HStack(alignment: .center) {
      Text(title)
        .counterTextStyle(.sheetTitleCompact)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Spacer(minLength: SpaceToken.u1)

      if let trailingTitle, let onTrailing {
        Button(trailingTitle) {
          CounterKeyboard.resign()
          onTrailing()
        }
        .counterTextStyle(.settingsRowLabel, color: isTrailingEnabled ? .primary : .disabled)
        .buttonStyle(.plain)
        .disabled(!isTrailingEnabled)
        .accessibilityIdentifier("sheet-dismiss")
        .accessibilityLabel(trailingTitle)
      }
    }
    .padding(.horizontal, SheetToken.horizontal)
    .padding(.top, SpaceToken.u1)
    .padding(.bottom, SpaceToken.u1)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(colors.surfaceSheet)
    .opacity(collapseProgress)
    .accessibilityHidden(collapseProgress < 0.15)
  }
}

/// Scroll container that collapses `title` into a compact sticky bar as content scrolls.
struct CounterSheetScroll<Content: View>: View {
  let title: String
  @ViewBuilder var content: () -> Content

  @State private var collapseProgress: CGFloat = 0

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: SettingsToken.sectionGap) {
        CounterSheetHeader(title: title, collapseProgress: collapseProgress)
        content()
      }
    }
    .onScrollGeometryChange(for: CGFloat.self) { geometry in
      geometry.contentOffset.y + geometry.contentInsets.top
    } action: { _, offset in
      let next = min(max(offset / SheetToken.titleCollapseDistance, 0), 1)
      if abs(next - collapseProgress) > 0.01 {
        collapseProgress = next
      }
    }
    // Overlay (not safe-area inset) so the compact bar doesn't reserve space while collapsed.
    .overlay(alignment: .top) {
      CounterSheetStickyTitle(title: title, collapseProgress: collapseProgress)
    }
  }
}

#Preview {
  CounterSheetScroll(title: "Settings") {
    Text("Content")
      .padding(.horizontal, SheetToken.horizontal)
  }
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

  private var accessibilityID: String {
    "destructive-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))"
  }

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
    .accessibilityLabel(label)
    .accessibilityIdentifier(accessibilityID)
  }
}
