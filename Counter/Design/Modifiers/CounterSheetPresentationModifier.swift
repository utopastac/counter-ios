import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Controls how a modal sheet sizes itself.
///
/// - `offsetPeek` leaves a sliver of the presenting content visible above the sheet.
///   Note: iOS only stacks a further nested `.sheet` correctly on top of a sheet that's
///   at the `.large` detent. Any non-`.large` detent (including this custom offset one)
///   causes a nested child sheet to visually replace the parent instead of layering over
///   it, so this style must not be used on a screen that itself presents another sheet.
/// - `full` fills the `.large` detent. Safe to host a nested `.sheet` on top of.
/// - `cornerRadiusOnly` only applies the shared corner radius, leaving detents/sizing to
///   the caller (used by sheets that size themselves, e.g. `AmountEntrySheet`).
enum CounterSheetPresentationStyle {
  case offsetPeek
  case full
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
        .background {
          SheetTopOffsetConfigurator(topOffset: SheetToken.topOffset)
        }
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
        .presentationSizing(.page)
        .presentationBackground {
          SheetToken.halfSheetTopCornerShape
            .fill(colors.surfaceSheet)
        }
    case .full:
      content
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.large])
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

#if canImport(UIKit)
/// Ensures UIKit sheet detents honor the top offset when SwiftUI sizing expands to full height.
private struct SheetTopOffsetConfigurator: UIViewRepresentable {
  let topOffset: CGFloat

  /// A fixed identifier so repeated `updateUIView` calls resolve to the *same* detent
  /// instead of a freshly generated one each time, avoiding redundant reconfiguration.
  private static let detentIdentifier = UISheetPresentationController.Detent.Identifier("counterTopOffset")

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    DispatchQueue.main.async {
      guard let sheet = uiView.enclosingViewController?.sheetPresentationController else { return }
      guard sheet.selectedDetentIdentifier != Self.detentIdentifier else { return }

      let detent = UISheetPresentationController.Detent.custom(identifier: Self.detentIdentifier) { detentContext in
        max(320, detentContext.maximumDetentValue - topOffset)
      }

      sheet.detents = [detent]
      sheet.selectedDetentIdentifier = detent.identifier
      sheet.preferredCornerRadius = SheetToken.cornerRadius
    }
  }
}

private extension UIView {
  var enclosingViewController: UIViewController? {
    sequence(first: self as UIResponder, next: { $0.next })
      .compactMap { $0 as? UIViewController }
      .first
  }
}
#endif
