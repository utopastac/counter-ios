import Observation
import SwiftUI

/// Holds the live reveal drag offset and discrete interaction flags. Per-frame `cardOffset`
/// changes only invalidate the transform modifiers that read it — not `CounterPagerView`.
@Observable
final class RevealState {
  var cardOffset: CGFloat = 0
  /// True while a reveal drag or settle animation should block pager/list scrolling.
  var locksScroll = false
  /// True while a horizontal reveal drag is actively tracking.
  var isDragging = false
}

/// List at fixed width underneath; counter card slides right, scales, and rounds with spring physics.
struct CounterUnderlayReveal<List: View, Card: View>: View {
  let state: RevealState
  @Binding var isRevealed: Bool
  /// Compact mode uses a narrower underlay list and a smaller open drag offset.
  var isCompact = false
  @ViewBuilder var list: () -> List
  @ViewBuilder var card: () -> Card

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors

  private let listParallaxFraction: CGFloat = 0.06

  var body: some View {
    GeometryReader { geometry in
      let width = max(geometry.size.width, 1)
      let height = max(geometry.size.height, 1)
      let inset = SpaceToken.scrollContainerInset
      let cardWidth = RevealToken.cardContentWidth(forScreenWidth: width)
      let listWidth = RevealToken.listWidth(for: width, isCompact: isCompact)
      let maxScaleReduction = RevealToken.maxScaleReduction
      let maxOffset = RevealToken.openOffset(forCardWidth: cardWidth, isCompact: isCompact)

      ZStack(alignment: .topLeading) {
        colors.surfacePrimary
          .frame(width: width, height: height)

        list()
          .frame(width: listWidth, height: height, alignment: .topLeading)
          .modifier(
            ListRevealParallax(
              state: state,
              maxOffset: maxOffset,
              maxParallax: reduceMotion ? 0 : width * listParallaxFraction,
              reduceMotion: reduceMotion
            )
          )
          .allowsHitTesting(isRevealed)

        card()
          .frame(width: cardWidth, height: height, alignment: .topLeading)
          .modifier(
            CardRevealTransform(
              state: state,
              maxOffset: maxOffset,
              maxScaleReduction: maxScaleReduction,
              cornerRadius: RadiusToken.scrollContainer
            )
          )
          .offset(x: inset)
          // Block card controls while the list is peeking or mid-drag; the reveal pan
          // still receives touches on the card because child views opt out of hit testing.
          .counterRevealDragging(state.isDragging || isRevealed)
          .background {
            RevealPanBridge(
              state: state,
              maxOffset: maxOffset,
              isRevealed: $isRevealed,
              reduceMotion: reduceMotion
            )
          }
      }
      .frame(width: width, height: height, alignment: .topLeading)
    }
  }

  /// Locks pager/list scroll while a reveal animation is in flight.
  static func lockRevealScrollForAnimation(
    _ state: RevealState,
    reduceMotion: Bool
  ) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      state.locksScroll = true
    }

    let duration = reduceMotion ? MotionToken.reduceMotionDuration : MotionToken.revealSettleDuration
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(duration))
      var unlockTransaction = Transaction()
      unlockTransaction.disablesAnimations = true
      withTransaction(unlockTransaction) {
        state.locksScroll = false
      }
    }
  }

  /// Horizontal offset when the list is fully revealed.
  static func openOffset(for width: CGFloat, isCompact: Bool = false) -> CGFloat {
    RevealToken.openOffset(forScreenWidth: width, isCompact: isCompact)
  }
}

private enum RevealMetrics {
  static func progress(for offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
    guard maxOffset > 0 else { return 0 }
    return min(max(offset / maxOffset, 0), 1)
  }
}

private struct CardRevealTransform: ViewModifier {
  @Environment(\.semanticColors) private var colors

  var state: RevealState
  let maxOffset: CGFloat
  let maxScaleReduction: CGFloat
  let cornerRadius: CGFloat

  private var progress: CGFloat {
    RevealMetrics.progress(for: state.cardOffset, maxOffset: maxOffset)
  }

  private var scale: CGFloat {
    1 - progress * maxScaleReduction
  }

  func body(content: Content) -> some View {
    content
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(ComponentColor.revealCardStroke(colors, progress: progress), lineWidth: 1)
      }
      .scaleEffect(scale, anchor: .topTrailing)
      .offset(x: state.cardOffset)
  }
}

private struct ListRevealParallax: ViewModifier {
  var state: RevealState
  let maxOffset: CGFloat
  let maxParallax: CGFloat
  let reduceMotion: Bool

  private let hiddenScale: CGFloat = 0.94
  private let hiddenBlur: CGFloat = 7

  private var progress: CGFloat {
    RevealMetrics.progress(for: state.cardOffset, maxOffset: maxOffset)
  }

  private var scale: CGFloat {
    guard !reduceMotion else { return 1 }
    return hiddenScale + progress * (1 - hiddenScale)
  }

  private var opacity: Double {
    Double(progress)
  }

  private var blur: CGFloat {
    guard !reduceMotion else { return 0 }
    return hiddenBlur * (1 - progress)
  }

  func body(content: Content) -> some View {
    content
      .scaleEffect(x: scale, y: 1, anchor: .leading)
      .opacity(opacity)
      .blur(radius: blur)
      .offset(x: -maxParallax * (1 - progress))
  }
}
