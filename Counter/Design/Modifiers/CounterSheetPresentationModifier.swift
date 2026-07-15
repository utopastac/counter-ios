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

extension View {
  /// Applies the standard top corner radius and sizing for modal sheets.
  func counterSheetPresentation(_ style: CounterSheetPresentationStyle = .offsetPeek) -> some View {
    modifier(CounterSheetPresentationModifier(style: style))
  }
}

private struct CounterSheetPresentationModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let style: CounterSheetPresentationStyle

  func body(content: Content) -> some View {
    switch style {
    case .offsetPeek:
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
        .presentationBackground {
          SheetToken.halfSheetTopCornerShape
            .fill(colors.surfaceSheet)
        }
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
