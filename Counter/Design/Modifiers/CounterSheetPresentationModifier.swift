import Observation
import QuartzCore
import SwiftData
import SwiftUI
import UIKit

/// Controls how a modal sheet sizes itself.
///
/// - `offsetPeek` uses a custom detent so the presenting content remains visible above
///   the sheet, and keeps the system Liquid Glass sheet background.
/// - `cornerRadiusOnly` only applies the shared corner radius, leaving detents/sizing to
///   the caller, and keeps an opaque sheet fill.
/// - `cornerRadiusGlass` is the same as `cornerRadiusOnly` but keeps the system Liquid
///   Glass sheet background (used by `AmountEntrySheet`).
enum CounterSheetPresentationStyle {
  case offsetPeek
  /// Shared corner radius only; keeps the opaque sheet fill.
  case cornerRadiusOnly
  /// Shared corner radius with system Liquid Glass.
  case cornerRadiusGlass
}

extension View {
  /// Applies the standard top corner radius and sizing for modal sheets.
  func counterSheetPresentation(_ style: CounterSheetPresentationStyle = .offsetPeek) -> some View {
    modifier(CounterSheetPresentationModifier(style: style))
  }

  /// Blurs and dims the presenting content in proportion to sheet presentation progress.
  func counterModalScrim(progress: CGFloat) -> some View {
    modifier(CounterModalScrimModifier(progress: progress))
  }
}

private struct CounterSheetPresentationModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let style: CounterSheetPresentationStyle

  func body(content: Content) -> some View {
    switch style {
    case .offsetPeek:
      // No `presentationBackground` — partial-height sheets get system Liquid Glass on iOS 26+.
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(.clear, for: .navigation)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    case .cornerRadiusOnly:
      content
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationContentInteraction(.scrolls)
        .presentationBackground(colors.surfaceSheet)
    case .cornerRadiusGlass:
      content
        .containerBackground(.clear, for: .navigation)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationContentInteraction(.scrolls)
    }
  }
}

private struct CounterModalScrimModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let progress: CGFloat

  private var clampedProgress: CGFloat {
    min(max(progress, 0), 1)
  }

  func body(content: Content) -> some View {
    content
      .blur(radius: SheetToken.backdropBlurRadius * clampedProgress)
      .overlay {
        ComponentColor.modalScrim(colors)
          .opacity(clampedProgress)
          .ignoresSafeArea()
          .allowsHitTesting(false)
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

// MARK: - App-level sheet routing
//
// Sheets are presented from a zero-size sibling in `ContentView`, not from inside the pager.
// Attaching `.sheet` to the pager (or pages inside its scroll view) makes iOS shrink the
// presenter's safe area for the card-stack effect, which shifts paging scroll content on
// present and again on dismiss. A sibling presenter keeps the pager's layout untouched.

enum CounterSheetRoute: Identifiable, Equatable {
  case buttonSettings(counterID: UUID)
  case addCounter
  case customAmount(counterID: UUID)
  case editEntry(entryID: UUID, value: Double)
  case history(counterID: UUID)
  case appSettings

  var id: String {
    switch self {
    case .buttonSettings(let counterID):
      "buttonSettings-\(counterID.uuidString)"
    case .addCounter:
      "addCounter"
    case .customAmount(let counterID):
      "customAmount-\(counterID.uuidString)"
    case .editEntry(let entryID, _):
      "editEntry-\(entryID.uuidString)"
    case .history(let counterID):
      "history-\(counterID.uuidString)"
    case .appSettings:
      "appSettings"
    }
  }
}

@Observable
@MainActor
final class CounterSheetCoordinator {
  var route: CounterSheetRoute? {
    didSet {
      guard route != oldValue else { return }
      // Swipe-to-dismiss clears the route while the sheet is still on screen.
      if route == nil {
        scrimSampler?.trackDismissal()
      }
    }
  }

  /// 0…1 how far the active sheet has risen. Tracks the sheet's on-screen frame,
  /// including present, drag, and dismiss — not a separate timed fade.
  private(set) var scrimProgress: CGFloat = 0
  var onCounterCreated: ((CustomCounter) -> Void)?

  /// Scrim over the whole pager (list + counters) while a sheet is moving or up.
  var pagerScrimProgress: CGFloat {
    scrimProgress
  }

  @ObservationIgnored private var scrimSampler: SheetScrimSampler?

  func present(_ route: CounterSheetRoute) {
    setScrimProgress(0)
    self.route = route
    sampler().trackPresentation()
  }

  func dismiss() {
    route = nil
  }

  fileprivate func ingestSheetSample(_ sample: SheetScrimSample) {
    switch sample {
    case .noSheet:
      guard route == nil else { return }
      setScrimProgress(0)
      scrimSampler?.stop()
    case .waitingForMotion:
      break
    case .progress(let value):
      setScrimProgress(value)
    }
  }

  private func sampler() -> SheetScrimSampler {
    if let scrimSampler { return scrimSampler }
    let sampler = SheetScrimSampler()
    sampler.coordinator = self
    scrimSampler = sampler
    return sampler
  }

  private func setScrimProgress(_ value: CGFloat) {
    let clamped = min(max(value, 0), 1)
    guard abs(clamped - scrimProgress) > 0.001 else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      scrimProgress = clamped
    }
  }
}

/// Where the presented sheet is, in scrim terms.
private enum SheetScrimSample {
  /// No presented sheet view is attached to a window.
  case noSheet
  /// The presentation layer is still parked on the final frame; keep the current scrim.
  case waitingForMotion
  /// 0 = sheet below the screen, 1 = sheet fully risen.
  case progress(CGFloat)
}

/// Reads the sheet chrome's presentation layer each frame.
///
/// SwiftUI geometry inside a sheet is the resting layout frame as soon as the
/// sheet appears, so a blur driven from that (or from a fixed present duration)
/// snaps to fully blurred. The presentation layer is the frame actually on screen.
@MainActor
private final class SheetScrimSampler: NSObject {
  weak var coordinator: CounterSheetCoordinator?

  private var displayLink: CADisplayLink?
  private weak var sheetChrome: UIView?
  private var hasTrackedMotion = false
  private var restSamplesBeforeMotion = 0

  func trackPresentation() {
    sheetChrome = nil
    hasTrackedMotion = false
    restSamplesBeforeMotion = 0
    start()
  }

  func trackDismissal() {
    start()
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
    sheetChrome = nil
  }

  private func start() {
    guard displayLink == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(step))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  @objc private func step() {
    coordinator?.ingestSheetSample(currentSample())
  }

  private func currentSample() -> SheetScrimSample {
    guard let chrome = resolveSheetChrome(), let window = chrome.window else {
      return .noSheet
    }
    let frame = visualFrame(of: chrome, in: window)
    let progress = Self.fraction(
      sheetTop: frame.minY,
      sheetHeight: frame.height,
      containerHeight: window.bounds.height
    )

    // UIKit commits the resting frame for a frame or two before the present
    // animation moves the presentation layer. Don't treat that as "fully open".
    if !hasTrackedMotion {
      if progress < 0.98 {
        hasTrackedMotion = true
      } else {
        restSamplesBeforeMotion += 1
        if restSamplesBeforeMotion < 3 {
          return .waitingForMotion
        }
        hasTrackedMotion = true
      }
    }

    return .progress(progress)
  }

  /// 0 when `sheetTop` is at the bottom of the container, 1 when the whole sheet has risen.
  private static func fraction(sheetTop: CGFloat, sheetHeight: CGFloat, containerHeight: CGFloat) -> CGFloat {
    guard sheetHeight > 1, containerHeight > 1 else { return 0 }
    return min(max((containerHeight - sheetTop) / sheetHeight, 0), 1)
  }

  private func resolveSheetChrome() -> UIView? {
    if let presented = foregroundPresentedSheetView(), let window = presented.window {
      let chrome = movingSheetChrome(containing: presented, in: window)
      sheetChrome = chrome
      return chrome
    }
    if let sheetChrome, sheetChrome.window != nil {
      return sheetChrome
    }
    return nil
  }

  /// Prefer the ancestor that is still lowest on screen. Sheet content often sits at its
  /// resting frame immediately while a parent platter is the view actually sliding up.
  private func movingSheetChrome(containing content: UIView, in window: UIWindow) -> UIView {
    var best = sheetChromeView(containing: content, in: window)
    var bestTop = visualFrame(of: best, in: window).minY
    var current: UIView? = content
    while let view = current, view !== window {
      let frame = visualFrame(of: view, in: window)
      let looksLikeSheet = frame.height > 200
        && frame.height < window.bounds.height - 1
        && frame.width > window.bounds.width * 0.5
      if looksLikeSheet, frame.minY > bestTop + 1 {
        best = view
        bestTop = frame.minY
      }
      current = view.superview
    }
    return best
  }

  private func foregroundPresentedSheetView() -> UIView? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let active = scenes.filter { $0.activationState == .foregroundActive }
    for scene in active.isEmpty ? scenes : active {
      for window in scene.windows {
        if let view = window.rootViewController?.presentedViewController?.view, view.window != nil {
          return view
        }
      }
    }
    return nil
  }

  /// Outermost view that is the sheet itself, not the full-screen transition container.
  private func sheetChromeView(containing content: UIView, in window: UIWindow) -> UIView {
    let fullScreen = window.bounds.height - 1
    var chrome = content
    if content.bounds.height >= fullScreen,
       let platter = largestPartialSubview(of: content, shorterThan: fullScreen) {
      chrome = platter
    }
    var current: UIView? = chrome.superview
    while let view = current, view !== window {
      if view.bounds.height >= fullScreen { break }
      chrome = view
      current = view.superview
    }
    return chrome
  }

  private func largestPartialSubview(of view: UIView, shorterThan fullScreen: CGFloat) -> UIView? {
    view.subviews
      .filter { $0.bounds.height > 200 && $0.bounds.height < fullScreen && $0.bounds.width > 200 }
      .max { $0.bounds.height < $1.bounds.height }
  }

  private func visualFrame(of view: UIView, in window: UIWindow) -> CGRect {
    let layer = view.layer.presentation() ?? view.layer
    let target = window.layer.presentation() ?? window.layer
    let frame = layer.convert(layer.bounds, to: target)
    if frame.height > 1 { return frame }
    return view.convert(view.bounds, to: window)
  }
}

/// Invisible sibling that owns every app sheet presentation.
struct CounterSheetHost: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var coordinator: CounterSheetCoordinator
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .allowsHitTesting(false)
      .sheet(item: $coordinator.route) { route in
        sheetContent(for: route)
          .counterDesignSystemFromColorScheme()
      }
  }

  @ViewBuilder
  private func sheetContent(for route: CounterSheetRoute) -> some View {
    switch route {
    case .buttonSettings(let counterID):
      if let counter = counter(for: counterID) {
        CounterButtonSettingsSheetContent(counter: counter)
      }
    case .addCounter:
      CreateCounterView { counter in
        coordinator.onCounterCreated?(counter)
      }
    case .customAmount(let counterID):
      if let counter = counter(for: counterID) {
        CounterCustomAmountSheetContent(counter: counter)
      }
    case .editEntry(let entryID, let value):
      CounterEditEntrySheetContent(entryID: entryID, initialValue: value)
    case .history(let counterID):
      if let counter = counter(for: counterID) {
        CounterHistoryView(counter: counter)
      }
    case .appSettings:
      AppSettingsView()
    }
  }

  private func counter(for id: UUID) -> CustomCounter? {
    counters.first { $0.id == id }
  }
}

private struct CounterButtonSettingsSheetContent: View {
  @Environment(\.modelContext) private var modelContext
  @Bindable var counter: CustomCounter

  var body: some View {
    CounterSettingsView(
      values: counter.presetAmounts,
      counter: counter,
      onSave: { save in
        if let name = save.name {
          counter.name = CustomCounter.normalizedName(from: name)
        }
        counter.presetAmounts = save.buttonValues
        counter.goal = save.goal.map(CounterAmount.rounded)
        counter.unit = save.unit
        counter.resetPeriod = save.resetPeriod
        counter.resetAnchorDay = save.resetAnchorDay
        counter.goalDirection = save.goalDirection
        if let paletteIndex = save.paletteIndex {
          counter.paletteIndex = paletteIndex
        }
        counter.progressRingWidthRaw = save.progressRingWidthRaw
        counter.progressRingGlowRaw = save.progressRingGlowRaw
        counter.historyAverageActiveDaysOnlyRaw = save.historyAverageActiveDaysOnlyRaw
        counter.historyPerPeriodRaw = save.historyPerPeriodRaw
        counter.headerDisplayRaw = save.headerDisplayRaw
        WidgetSnapshotSync.publish(counter: counter, in: modelContext)
        WatchSyncEngine.publishCounterUpsert(counter)
      },
      onDelete: {
        let counterID = counter.id
        modelContext.delete(counter)
        AppLog.attempt("Save counter delete") { try modelContext.save() }
        WidgetSnapshot.reloadTimelines()
        WatchSyncEngine.publishCounterDelete(counterID)
      },
      onPaletteChange: { index in
        counter.paletteIndex = index
        WidgetSnapshotSync.publish(counter: counter, in: modelContext)
        WatchSyncEngine.publishCounterUpsert(counter)
      }
    )
  }
}

private struct CounterCustomAmountSheetContent: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.hapticsEnabledKey) private var isHapticsEnabled = true
  @State private var impactHapticTrigger = 0
  let counter: CustomCounter

  var body: some View {
    CustomAmountSheet { value in
      _ = EntryActions.addCounterEntry(value: value, counter: counter, in: modelContext)
      impactHapticTrigger &+= 1
      AppSounds.log()
      WidgetSnapshotSync.publish(counter: counter, in: modelContext)
    }
    .sensoryFeedback(.impact(weight: .light), trigger: impactHapticTrigger) { _, _ in
      isHapticsEnabled
    }
  }
}

private struct CounterEditEntrySheetContent: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.hapticsEnabledKey) private var isHapticsEnabled = true
  @State private var impactHapticTrigger = 0

  let entryID: UUID
  let initialValue: Double

  var body: some View {
    EditAmountSheet(initialValue: initialValue) { newValue in
      EntryActions.updateCounterEntry(id: entryID, value: newValue, in: modelContext)
      impactHapticTrigger &+= 1
      AppSounds.log()
      if let entry = EntryActions.fetchCounterEntry(id: entryID, in: modelContext),
         let counter = entry.counter
      {
        WidgetSnapshotSync.publish(counter: counter, in: modelContext)
      }
    }
    .sensoryFeedback(.impact(weight: .light), trigger: impactHapticTrigger) { _, _ in
      isHapticsEnabled
    }
  }
}
