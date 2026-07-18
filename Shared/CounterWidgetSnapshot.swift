import Foundation

struct CounterWidgetSnapshot {
  let counterID: String
  let title: String
  let paletteIndex: Int
  let heroValue: String
  /// Full-sentence, capitalized subtitle (e.g. `"80 Remaining"`) — matches the string the
  /// main app shows under its hero number (`GoalProgress.heroSubtitle`), rather than the
  /// single-word caption used elsewhere, so the widget reads the same as the app.
  let heroSubtitle: String
  let ringProgress: GoalProgress?
  let buttonValues: [Double]
  let lastUpdated: Date?

  static let placeholder = CounterWidgetSnapshot(
    counterID: "preview",
    title: CustomCounter.untitledName,
    paletteIndex: 0,
    heroValue: "2424",
    heroSubtitle: "80 Remaining",
    ringProgress: GoalProgress(current: 2424, goal: 2504, direction: .countDown),
    buttonValues: [5, 10, 25, 50, 100, 200, 500, 1000],
    lastUpdated: .now
  )
}
