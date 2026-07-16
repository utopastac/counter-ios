import SwiftUI

/// Controls how a modal sheet sizes itself.
///
/// - `offsetPeek` uses a custom detent so the presenting content remains visible above
///   the sheet.
/// - `cornerRadiusOnly` only applies the shared corner radius, leaving detents/sizing to
///   the caller (used by sheets that size themselves, e.g. `AmountEntrySheet`).
enum CounterSheetPresentationStyle {
  case offsetPeek
  case cornerRadiusOnly
}

/// Stable IDs shared between a sheet's triggering button (`matchedTransitionSource`) and
/// its presented content (`navigationTransition(.zoom)`), so the two call sites — often in
/// different views — can't drift apart.
enum SheetTransitionID {
  static let buttonSettings = "buttonSettings"
  static let history = "history"
  static let addCounter = "addCounter"
  static let appSettings = "appSettings"

  static func allEntries(_ counterID: UUID) -> String {
    "allEntries-\(counterID.uuidString)"
  }
}

extension View {
  /// Applies the standard top corner radius and sizing for modal sheets.
  func counterSheetPresentation(_ style: CounterSheetPresentationStyle = .offsetPeek) -> some View {
    modifier(CounterSheetPresentationModifier(style: style))
  }
}

private struct CounterSheetPresentationModifier: ViewModifier {
  let style: CounterSheetPresentationStyle

  // iOS 26 gives partial-height sheets (any non-`.large` detent) an inset, floating
  // Liquid Glass background automatically. A custom `presentationBackground` would
  // paint over that system material, so both styles now only set sizing and let the
  // system supply the glass chrome.
  func body(content: Content) -> some View {
    switch style {
    case .offsetPeek:
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
    case .cornerRadiusOnly:
      content
        .presentationCornerRadius(SheetToken.cornerRadius)
    }
  }
}

extension PresentationDetent {
  static let counterOffsetLarge = Self.custom(CounterOffsetLargeDetent.self)
}

private struct CounterOffsetLargeDetent: CustomPresentationDetent {
  static func height(in context: Context) -> CGFloat? {
    max(320, context.maxDetentValue - SheetToken.topOffset)
  }
}
