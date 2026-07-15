import Foundation

struct CounterWidgetSnapshot {
  let counterID: String
  let title: String
  let paletteIndex: Int
  let heroValue: String
  let heroCaption: String
  let ringFraction: Double
  let buttonValues: [Int]
  let lastUpdated: Date?

  static let placeholder = CounterWidgetSnapshot(
    counterID: "preview",
    title: CustomCounter.untitledName,
    paletteIndex: 0,
    heroValue: "2424",
    heroCaption: "remaining",
    ringFraction: 0.72,
    buttonValues: [5, 10, 25, 50, 100, 200, 500, 1000],
    lastUpdated: .now
  )
}
