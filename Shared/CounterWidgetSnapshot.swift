import Foundation

/// One recent log row for the large home-screen widget (value + time + delete).
nonisolated struct CounterWidgetRecentEntry: Identifiable, Sendable, Hashable {
  let id: UUID
  let valueText: String
  let timestamp: Date
}

nonisolated struct CounterWidgetSnapshot: Sendable {
  let counterID: String
  let title: String
  let paletteIndex: Int
  /// Resolved ring width raw value (counter override or app default).
  let progressRingWidthRaw: String
  /// Resolved ring glow (counter override or app default).
  let progressRingGlowEnabled: Bool
  let heroValue: String
  /// Full-sentence, capitalized subtitle (e.g. `"80 Remaining"`) — matches the string the
  /// main app shows under its hero number (`GoalProgress.heroSubtitle`), rather than the
  /// single-word caption used elsewhere, so the widget reads the same as the app.
  let heroSubtitle: String
  let ringProgress: GoalProgress?
  let buttonValues: [Double]
  /// Newest-first current-period entries for the large widget (capped at
  /// `CounterWidgetSnapshot.recentEntryLimit`).
  let recentEntries: [CounterWidgetRecentEntry]
  let lastUpdated: Date?
  /// Configured counter was deleted (or otherwise missing from the store).
  let isUnavailable: Bool

  static let recentEntryLimit = 4

  var progressRingWidth: ProgressRingWidth {
    ProgressRingWidth(rawValue: progressRingWidthRaw) ?? .balanced
  }

  /// Gallery / loading sample — not shown when a real counter is missing.
  static let placeholder = CounterWidgetSnapshot(
    counterID: "preview",
    title: "Calories",
    paletteIndex: 0,
    progressRingWidthRaw: ProgressRingWidth.balanced.rawValue,
    progressRingGlowEnabled: false,
    heroValue: "0",
    heroSubtitle: "Remaining",
    ringProgress: GoalProgress(current: 0, goal: 2200, direction: .countDown),
    buttonValues: [5, 10, 25, 50, 100, 200, 500, 1000],
    recentEntries: [
      CounterWidgetRecentEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        valueText: "100",
        timestamp: Date.now.addingTimeInterval(-3600)
      ),
      CounterWidgetRecentEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        valueText: "50",
        timestamp: Date.now.addingTimeInterval(-7200)
      ),
      CounterWidgetRecentEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        valueText: "25",
        timestamp: Date.now.addingTimeInterval(-10_800)
      ),
      CounterWidgetRecentEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        valueText: "10",
        timestamp: Date.now.addingTimeInterval(-14_400)
      )
    ],
    lastUpdated: nil,
    isUnavailable: false
  )

  /// Explicit empty state when the widget's counter no longer exists.
  static let unavailable = CounterWidgetSnapshot(
    counterID: "",
    title: "Counter removed",
    paletteIndex: 0,
    progressRingWidthRaw: ProgressRingWidth.balanced.rawValue,
    progressRingGlowEnabled: false,
    heroValue: "",
    heroSubtitle: "Edit widget to choose another",
    ringProgress: nil,
    buttonValues: [],
    recentEntries: [],
    lastUpdated: nil,
    isUnavailable: true
  )
}
