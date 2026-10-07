import Observation
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

/// Publishes sheet frame progress into the coordinator so the presenter can blur progressively.
private struct CounterSheetScrimTrackingModifier: ViewModifier {
  let coordinator: CounterSheetCoordinator

  func body(content: Content) -> some View {
    content
      .onGeometryChange(for: CGRect.self) { proxy in
        proxy.frame(in: .global)
      } action: { _, frame in
        coordinator.updateScrimProgress(sheetFrame: frame)
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
      if route == nil {
        tracksSheetGeometry = false
        scrimProgress = 0
      }
    }
  }

  /// 0…1 how far the active sheet has risen on screen.
  /// Animates in on present; follows sheet geometry during interactive dismiss.
  var scrimProgress: CGFloat = 0
  var onCounterCreated: ((CustomCounter) -> Void)?

  /// Sheet content lays out at its final frame immediately, so geometry alone snaps
  /// blur to 1 on present. Ignore those reports until the sheet starts moving down.
  @ObservationIgnored private var tracksSheetGeometry = false

  /// Scrim over the whole pager (list + counters) while any sheet is up.
  var pagerScrimProgress: CGFloat {
    route == nil ? 0 : scrimProgress
  }

  func present(_ route: CounterSheetRoute) {
    tracksSheetGeometry = false
    self.route = route
    scrimProgress = 0
    withAnimation(MotionToken.sheetScrimPresent) {
      scrimProgress = 1
    }
  }

  func dismiss() {
    route = nil
  }

  func updateScrimProgress(sheetFrame frame: CGRect) {
    guard route != nil, frame.height > 1 else {
      if scrimProgress != 0 { scrimProgress = 0 }
      return
    }
    let screenHeight = Self.screenHeight
    guard screenHeight > 1 else { return }
    let next = min(max((screenHeight - frame.minY) / frame.height, 0), 1)

    // Present: content geometry jumps to ~1 immediately — keep the animated ramp.
    // Dismiss: progress drops as the sheet moves; switch to live tracking.
    if !tracksSheetGeometry {
      if next < 0.97 {
        tracksSheetGeometry = true
      } else {
        return
      }
    }

    guard abs(next - scrimProgress) > 0.002 else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      scrimProgress = next
    }
  }

  private static var screenHeight: CGFloat {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    if let height = scenes.first(where: { $0.activationState == .foregroundActive })?.screen.bounds.height {
      return height
    }
    return scenes.first?.screen.bounds.height ?? 0
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
          .modifier(CounterSheetScrimTrackingModifier(coordinator: coordinator))
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
