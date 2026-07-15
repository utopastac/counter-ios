import SwiftUI

/// List at fixed width underneath; counter card slides right, scales, and rounds with spring physics.
struct CounterUnderlayReveal<List: View, Card: View>: View {
  @Binding var cardOffset: CGFloat
  @Binding var isRevealed: Bool
  @Binding var locksRevealScroll: Bool
  @ViewBuilder var list: () -> List
  @ViewBuilder var card: () -> Card

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.semanticColors) private var colors

  @State private var dragStartOffset: CGFloat = 0
  @State private var isDraggingReveal = false
  @State private var dragAxis: RevealDragAxis?

  private let listParallaxFraction: CGFloat = 0.06

  var body: some View {
    GeometryReader { geometry in
      let width = max(geometry.size.width, 1)
      let height = max(geometry.size.height, 1)
      let inset = SpaceToken.scrollContainerInset
      let cardWidth = RevealToken.cardContentWidth(forScreenWidth: width)
      let listWidth = RevealToken.listWidth(for: width)
      let maxScaleReduction = RevealToken.maxScaleReduction
      let maxOffset = RevealToken.openOffset(forCardWidth: cardWidth)
      let progress = RevealMetrics.progress(for: cardOffset, maxOffset: maxOffset)

      ZStack(alignment: .topLeading) {
        colors.surfacePrimary
          .frame(width: width, height: height)

        list()
          .frame(width: listWidth, height: height, alignment: .topLeading)
          .modifier(
            ListRevealParallax(
              cardOffset: cardOffset,
              maxOffset: maxOffset,
              maxParallax: reduceMotion ? 0 : width * listParallaxFraction,
              reduceMotion: reduceMotion
            )
          )
          .allowsHitTesting(progress > 0.12)

        card()
          .frame(width: cardWidth, height: height, alignment: .topLeading)
          .modifier(
            CardRevealTransform(
              maxOffset: maxOffset,
              cardOffset: cardOffset,
              maxScaleReduction: maxScaleReduction,
              cornerRadius: RadiusToken.scrollContainer
            )
          )
          .offset(x: inset)
          .simultaneousGesture(revealGesture(maxOffset: maxOffset))
      }
      .frame(width: width, height: height, alignment: .topLeading)
    }
  }

  /// Locks pager/list scroll while a reveal animation is in flight.
  static func lockRevealScrollForAnimation(
    _ locksRevealScroll: Binding<Bool>,
    reduceMotion: Bool
  ) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      locksRevealScroll.wrappedValue = true
    }

    let duration = reduceMotion ? 0.2 : MotionToken.revealSettleDuration
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(duration))
      var unlockTransaction = Transaction()
      unlockTransaction.disablesAnimations = true
      withTransaction(unlockTransaction) {
        locksRevealScroll.wrappedValue = false
      }
    }
  }

  /// Horizontal offset when the list is fully revealed.
  static func openOffset(for width: CGFloat) -> CGFloat {
    RevealToken.openOffset(forScreenWidth: width)
  }

  private var settleSpring: Animation {
    MotionToken.settle(reduceMotion: reduceMotion)
  }

  private func revealGesture(maxOffset: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .onChanged { value in
        if dragAxis == nil {
          dragAxis = resolvedDragAxis(for: value)
          guard let dragAxis else { return }

          switch dragAxis {
          case .horizontal:
            isDraggingReveal = true
            dragStartOffset = cardOffset
            setRevealScrollLocked(true)
          case .vertical:
            return
          }
        }

        guard dragAxis == .horizontal, isDraggingReveal else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
          cardOffset = rubberBand(dragStartOffset + value.translation.width, max: maxOffset)
        }
      }
      .onEnded { value in
        let wasDragging = isDraggingReveal
        let axis = dragAxis
        isDraggingReveal = false
        dragAxis = nil

        guard wasDragging, axis == .horizontal else {
          setRevealScrollLocked(false)
          return
        }

        let predicted = rubberBand(
          dragStartOffset + value.predictedEndTranslation.width,
          max: maxOffset
        )
        let shouldOpen = shouldSettleOpen(
          predicted: predicted,
          maxOffset: maxOffset,
          startedOpen: dragStartOffset > maxOffset * 0.5
        )

        withAnimation(settleSpring) {
          cardOffset = shouldOpen ? maxOffset : 0
          isRevealed = shouldOpen
        }
        scheduleRevealScrollUnlock()
      }
  }

  private func resolvedDragAxis(for value: DragGesture.Value) -> RevealDragAxis? {
    let horizontal = abs(value.translation.width)
    let vertical = abs(value.translation.height)
    guard max(horizontal, vertical) >= RevealToken.axisDecisionDistance else { return nil }
    return horizontal > vertical ? .horizontal : .vertical
  }

  private func setRevealScrollLocked(_ locked: Bool) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      locksRevealScroll = locked
    }
  }

  private func scheduleRevealScrollUnlock() {
    let duration = reduceMotion ? 0.2 : MotionToken.revealSettleDuration
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(duration))
      setRevealScrollLocked(false)
    }
  }

  private func shouldSettleOpen(
    predicted: CGFloat,
    maxOffset: CGFloat,
    startedOpen: Bool
  ) -> Bool {
    guard maxOffset > 0 else { return false }
    let threshold = maxOffset * (startedOpen ? 0.45 : 0.35)
    return predicted > threshold
  }

  private func rubberBand(_ value: CGFloat, max: CGFloat) -> CGFloat {
    if value > max {
      return max + (value - max) * 0.16
    }
    if value < 0 {
      return value * 0.16
    }
    return value
  }
}

private enum RevealDragAxis {
  case horizontal
  case vertical
}

private enum RevealMetrics {
  static func progress(for offset: CGFloat, maxOffset: CGFloat) -> CGFloat {
    guard maxOffset > 0 else { return 0 }
    return min(max(offset / maxOffset, 0), 1)
  }
}

private struct CardRevealTransform: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let maxOffset: CGFloat
  let cardOffset: CGFloat
  let maxScaleReduction: CGFloat
  let cornerRadius: CGFloat

  private var progress: CGFloat {
    RevealMetrics.progress(for: cardOffset, maxOffset: maxOffset)
  }

  private var scale: CGFloat {
    1 - progress * maxScaleReduction
  }

  func body(content: Content) -> some View {
    let shadow = ShadowToken.reveal(progress: progress)

    content
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(ComponentColor.revealCardStroke(colors, progress: progress), lineWidth: 1)
      }
      .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
      .scaleEffect(scale, anchor: .topTrailing)
      .offset(x: cardOffset)
  }
}

private struct ListRevealParallax: ViewModifier {
  let cardOffset: CGFloat
  let maxOffset: CGFloat
  let maxParallax: CGFloat
  let reduceMotion: Bool

  private let hiddenScale: CGFloat = 0.94
  private let hiddenBlur: CGFloat = 7

  private var progress: CGFloat {
    RevealMetrics.progress(for: cardOffset, maxOffset: maxOffset)
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
