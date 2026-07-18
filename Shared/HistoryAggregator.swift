import Foundation
import SwiftData

nonisolated enum HistoryAggregator {
  static func counterTotal(from entries: [CounterEntry], on date: Date) -> Double {
    let hundredths = entries
      .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
      .reduce(0) { $0 + $1.value }
    return CounterAmount.display(hundredths)
  }

  static func groupedCounterTotals(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date = .now,
    calendar: Calendar = .current
  ) -> [DailyValue] {
    let startOfEndDay = calendar.startOfDay(for: date)

    switch period {
    case .daily:
      return (0..<period.dayCount).compactMap { hour in
        guard let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfEndDay),
              let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)
        else { return nil }

        let hundredths = entries
          .filter { $0.timestamp >= hourStart && $0.timestamp < hourEnd }
          .reduce(0) { $0 + $1.value }

        return DailyValue(date: hourStart, value: CounterAmount.display(hundredths))
      }

    case .weekly:
      return (0..<period.dayCount).compactMap { weekOffset in
        guard
          let weekEnd = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: startOfEndDay),
          let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd),
          let weekEndExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: weekEnd))
        else { return nil }

        let hundredths = entries
          .filter {
            $0.timestamp >= calendar.startOfDay(for: weekStart) &&
            $0.timestamp < weekEndExclusive
          }
          .reduce(0) { $0 + $1.value }

        return DailyValue(date: calendar.startOfDay(for: weekEnd), value: CounterAmount.display(hundredths))
      }
      .reversed()

    case .monthly:
      return (0..<period.dayCount).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfEndDay) else { return nil }
        let total = counterTotal(from: entries, on: day)
        return DailyValue(date: day, value: total)
      }
      .reversed()
    }
  }

  /// Bucket for a chart bar — used when opening the entry editor from history.
  static func bucketRange(
    for date: Date,
    period: HistoryPeriod,
    calendar: Calendar = .current
  ) -> CounterPeriodRange {
    switch period {
    case .daily:
      let hourStart = calendar.date(
        bySettingHour: calendar.component(.hour, from: date),
        minute: 0,
        second: 0,
        of: date
      ) ?? date
      let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart
      return CounterPeriodRange(start: hourStart, end: hourEnd)
    case .monthly:
      let startOfDay = calendar.startOfDay(for: date)
      let end = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
      return CounterPeriodRange(start: startOfDay, end: end)
    case .weekly:
      let startOfDay = calendar.startOfDay(for: date)
      let weekStart = calendar.date(byAdding: .day, value: -6, to: startOfDay) ?? startOfDay
      let start = calendar.startOfDay(for: weekStart)
      let end = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
      return CounterPeriodRange(start: start, end: end)
    }
  }

  /// How many days to shift the chart window for one swipe step.
  static func windowStepDays(for period: HistoryPeriod) -> Int {
    switch period {
    case .daily: 1
    case .weekly: period.dayCount * 7
    case .monthly: period.dayCount
    }
  }

  /// End date for a chart window (`0` = current period ending today).
  static func endingDate(
    forWindowOffset offset: Int,
    period: HistoryPeriod,
    relativeTo date: Date = .now,
    calendar: Calendar = .current
  ) -> Date {
    let today = calendar.startOfDay(for: date)
    let stepDays = windowStepDays(for: period)
    return calendar.date(byAdding: .day, value: -(offset * stepDays), to: today) ?? today
  }

  /// Farthest window offset available for paging.
  /// Uses entry history when present, otherwise a Health-like browseable past.
  static func maxWindowOffset(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    relativeTo date: Date = .now,
    calendar: Calendar = .current
  ) -> Int {
    let minimumBrowseable = 51 // 52 pages including the current window
    guard let earliest = entries.map(\.timestamp).min() else { return minimumBrowseable }
    let start = calendar.startOfDay(for: earliest)
    let end = calendar.startOfDay(for: date)
    let step = windowStepDays(for: period)
    guard step > 0,
          let days = calendar.dateComponents([.day], from: start, to: end).day,
          days > 0
    else { return minimumBrowseable }
    return max(days / step, minimumBrowseable)
  }
}
