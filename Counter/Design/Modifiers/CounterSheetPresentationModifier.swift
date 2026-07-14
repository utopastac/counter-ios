import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension View {
  /// Applies the standard top corner radius and offset large detent for modal sheets.
  func counterSheetPresentation(includeOffsetDetent: Bool = true) -> some View {
    modifier(CounterSheetPresentationModifier(includeOffsetDetent: includeOffsetDetent))
  }
}

private struct CounterSheetPresentationModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let includeOffsetDetent: Bool

  func body(content: Content) -> some View {
    if includeOffsetDetent {
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
    } else {
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

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    DispatchQueue.main.async {
      guard let sheet = uiView.enclosingViewController?.sheetPresentationController else { return }

      let detent = UISheetPresentationController.Detent.custom { detentContext in
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
