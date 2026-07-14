import Foundation
import SwiftData

enum HistoryAggregator {
  static func counterTotal(from entries: [CounterEntry], for counter: CustomCounter, on date: Date = .now) -> Int {
    CounterPeriodCalculator.total(from: entries, for: counter, on: date)
  }

  static func counterTotal(from entries: [CounterEntry], on date: Date) -> Int {
    entries
      .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
      .reduce(0) { $0 + $1.value }
  }

  static func groupedCounterTotals(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date = .now
  ) -> [DailyValue] {
    let calendar = Calendar.current
    let startOfEndDay = calendar.startOfDay(for: date)

    switch period {
    case .daily:
      return (0..<period.dayCount).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfEndDay) else { return nil }
        let total = counterTotal(from: entries, on: day)
        return DailyValue(date: day, value: Double(total))
      }
      .reversed()

    case .weekly:
      return (0..<period.dayCount).compactMap { weekOffset in
        guard
          let weekEnd = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: startOfEndDay),
          let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd)
        else { return nil }

        let total = entries
          .filter {
            $0.timestamp >= calendar.startOfDay(for: weekStart) &&
            $0.timestamp <= calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: weekEnd))!
          }
          .reduce(0) { $0 + $1.value }

        return DailyValue(date: calendar.startOfDay(for: weekEnd), value: Double(total))
      }
      .reversed()

    case .monthly:
      return (0..<period.dayCount).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfEndDay) else { return nil }
        let total = counterTotal(from: entries, on: day)
        return DailyValue(date: day, value: Double(total))
      }
      .reversed()
    }
  }
}
