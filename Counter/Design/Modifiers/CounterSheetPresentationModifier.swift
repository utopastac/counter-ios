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

  /// Dims the presenting content with app-defined modal semantics while a sheet is active.
  func counterModalScrim(isPresented: Bool) -> some View {
    modifier(CounterModalScrimModifier(isPresented: isPresented))
  }
}

private struct CounterSheetPresentationModifier: ViewModifier {
  let style: CounterSheetPresentationStyle

  // iOS 26 gives partial-height sheets (any non-`.large` detent) an inset, floating
  // Liquid Glass background automatically. A custom `presentationBackground` would
  // paint over that system material, so both styles only set sizing and let the
  // system supply the glass chrome. `.presentationContentInteraction(.scrolls)` keeps
  // downward pans scrolling sheet content instead of dismissing on tiny movements.
  func body(content: Content) -> some View {
    switch style {
    case .offsetPeek:
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    case .cornerRadiusOnly:
      content
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationContentInteraction(.scrolls)
    }
  }
}

private struct CounterModalScrimModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let isPresented: Bool

  func body(content: Content) -> some View {
    content
      .overlay {
        if isPresented {
          ComponentColor.modalScrim(colors)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.18), value: isPresented)
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
