import Observation
import SwiftData
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
  @Environment(\.semanticColors) private var colors

  let style: CounterSheetPresentationStyle

  func body(content: Content) -> some View {
    switch style {
    case .offsetPeek:
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationDetents([.counterOffsetLarge])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .presentationBackground(colors.surfaceSheet)
    case .cornerRadiusOnly:
      content
        .presentationCornerRadius(SheetToken.cornerRadius)
        .presentationContentInteraction(.scrolls)
        .presentationBackground(colors.surfaceSheet)
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

// MARK: - App-level sheet routing
//
// Sheets are presented from a zero-size sibling in `ContentView`, not from inside the pager.
// Attaching `.sheet` to the pager (or pages inside its scroll view) makes iOS shrink the
// presenter's safe area for the card-stack effect, which shifts paging scroll content on
// present and again on dismiss. A sibling presenter keeps the pager's layout untouched.

enum CounterSheetRoute: Identifiable, Equatable {
  case buttonSettings(counterID: UUID)
  case history(counterID: UUID)
  case addCounter
  case customAmount(counterID: UUID)
  case entryLog(counterID: UUID)
  case appSettings

  var id: String {
    switch self {
    case .buttonSettings(let counterID):
      "buttonSettings-\(counterID.uuidString)"
    case .history(let counterID):
      "history-\(counterID.uuidString)"
    case .addCounter:
      "addCounter"
    case .customAmount(let counterID):
      "customAmount-\(counterID.uuidString)"
    case .entryLog(let counterID):
      "entryLog-\(counterID.uuidString)"
    case .appSettings:
      "appSettings"
    }
  }

  /// Routes that dim the counter card behind the sheet.
  var dimsPagerCard: Bool {
    switch self {
    case .buttonSettings, .history, .addCounter, .customAmount, .entryLog:
      true
    case .appSettings:
      false
    }
  }
}

@Observable
@MainActor
final class CounterSheetCoordinator {
  var route: CounterSheetRoute?
  var onCounterCreated: ((CustomCounter) -> Void)?

  var isPagerScrimActive: Bool {
    route?.dimsPagerCard ?? false
  }

  func present(_ route: CounterSheetRoute) {
    self.route = route
  }

  func dismiss() {
    route = nil
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
    case .history(let counterID):
      if let counter = counter(for: counterID) {
        CounterHistoryView(counter: counter)
      }
    case .addCounter:
      CreateCounterView { counter in
        coordinator.onCounterCreated?(counter)
      }
    case .customAmount(let counterID):
      if let counter = counter(for: counterID) {
        CounterCustomAmountSheetContent(counter: counter)
      }
    case .entryLog(let counterID):
      if let counter = counter(for: counterID) {
        CounterTodayLogView(counter: counter)
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
      WidgetSnapshotSync.publish(counter: counter, in: modelContext)
    }
    .sensoryFeedback(.impact(weight: .light), trigger: impactHapticTrigger) { _, _ in
      isHapticsEnabled
    }
  }
}
