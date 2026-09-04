import Foundation
import SwiftData

/// Pre-buckets entry totals by calendar day and hour so history windows are O(buckets), not O(entries × buckets).
nonisolated struct HistoryEntryIndex: Sendable {
  private let dayTotals: [Date: Double]
  private let hourTotals: [Date: Double]
  let earliestTimestamp: Date?

  static let empty = HistoryEntryIndex(dayTotals: [:], hourTotals: [:], earliestTimestamp: nil)

  init(entries: [CounterEntry], calendar: Calendar = .current) {
    var days: [Date: Double] = [:]
    var hours: [Date: Double] = [:]
    var earliest: Date?

    days.reserveCapacity(min(entries.count, 512))
    hours.reserveCapacity(min(entries.count, 512))

    for entry in entries {
      let timestamp = entry.timestamp
      let amount = entry.value
      if earliest == nil || timestamp < earliest! {
        earliest = timestamp
      }

      let day = calendar.startOfDay(for: timestamp)
      days[day, default: 0] += amount

      let hour = calendar.date(
        bySettingHour: calendar.component(.hour, from: timestamp),
        minute: 0,
        second: 0,
        of: timestamp
      ) ?? timestamp
      hours[hour, default: 0] += amount
    }

    dayTotals = days
    hourTotals = hours
    earliestTimestamp = earliest
  }

  private init(dayTotals: [Date: Double], hourTotals: [Date: Double], earliestTimestamp: Date?) {
    self.dayTotals = dayTotals
    self.hourTotals = hourTotals
    self.earliestTimestamp = earliestTimestamp
  }

  func total(onDay date: Date, calendar: Calendar = .current) -> Double {
    dayTotals[calendar.startOfDay(for: date)] ?? 0
  }

  func total(inHourStarting hourStart: Date) -> Double {
    hourTotals[hourStart] ?? 0
  }

  func total(fromDay start: Date, beforeDay end: Date, calendar: Calendar = .current) -> Double {
    var total = 0.0
    var day = calendar.startOfDay(for: start)
    let endDay = calendar.startOfDay(for: end)
    while day < endDay {
      total += dayTotals[day] ?? 0
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
    }
    return total
  }
}

nonisolated enum HistoryAggregator {
  static func counterTotal(
    from entries: [CounterEntry],
    on date: Date,
    calendar: Calendar = .current
  ) -> Double {
    HistoryEntryIndex(entries: entries, calendar: calendar).total(onDay: date, calendar: calendar)
  }

  static func counterTotal(
    index: HistoryEntryIndex,
    on date: Date,
    calendar: Calendar = .current
  ) -> Double {
    index.total(onDay: date, calendar: calendar)
  }

  static func groupedCounterTotals(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date = .now,
    calendar: Calendar = .current
  ) -> [DailyValue] {
    groupedCounterTotals(
      index: HistoryEntryIndex(entries: entries, calendar: calendar),
      period: period,
      endingOn: date,
      calendar: calendar
    )
  }

  static func groupedCounterTotals(
    index: HistoryEntryIndex,
    period: HistoryPeriod,
    endingOn date: Date = .now,
    calendar: Calendar = .current
  ) -> [DailyValue] {
    let startOfEndDay = calendar.startOfDay(for: date)

    switch period {
    case .daily:
      return (0..<period.dayCount).compactMap { hour in
        guard let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfEndDay)
        else { return nil }
        return DailyValue(date: hourStart, value: index.total(inHourStarting: hourStart))
      }

    case .weekly:
      return (0..<period.dayCount).compactMap { weekOffset in
        guard
          let weekEnd = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: startOfEndDay),
          let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd),
          let weekEndExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: weekEnd))
        else { return nil }

        let total = index.total(
          fromDay: calendar.startOfDay(for: weekStart),
          beforeDay: weekEndExclusive,
          calendar: calendar
        )
        return DailyValue(date: calendar.startOfDay(for: weekEnd), value: total)
      }
      .reversed()

    case .monthly:
      return (0..<period.dayCount).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfEndDay) else { return nil }
        return DailyValue(date: day, value: index.total(onDay: day, calendar: calendar))
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
    maxWindowOffset(
      earliestTimestamp: entries.map(\.timestamp).min(),
      period: period,
      relativeTo: date,
      calendar: calendar
    )
  }

  static func maxWindowOffset(
    earliestTimestamp: Date?,
    period: HistoryPeriod,
    relativeTo date: Date = .now,
    calendar: Calendar = .current
  ) -> Int {
    let minimumBrowseable = 51 // 52 pages including the current window
    guard let earliest = earliestTimestamp else { return minimumBrowseable }
    let start = calendar.startOfDay(for: earliest)
    let end = calendar.startOfDay(for: date)
    let step = windowStepDays(for: period)
    guard step > 0,
          let days = calendar.dateComponents([.day], from: start, to: end).day,
          days > 0
    else { return minimumBrowseable }
    return max(days / step, minimumBrowseable)
  }

  static func windowCalendarDayCount(for period: HistoryPeriod) -> Int {
    switch period {
    case .daily: 1
    case .weekly: 7
    case .monthly: period.dayCount
    }
  }

  /// Daily rows for the history list — hourly for day view, otherwise one row per day
  /// in the visible week or month window.
  static func listDailyTotals(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date,
    calendar: Calendar = .current
  ) -> [DailyValue] {
    listDailyTotals(
      index: HistoryEntryIndex(entries: entries, calendar: calendar),
      period: period,
      endingOn: date,
      calendar: calendar
    )
  }

  static func listDailyTotals(
    index: HistoryEntryIndex,
    period: HistoryPeriod,
    endingOn date: Date,
    calendar: Calendar = .current
  ) -> [DailyValue] {
    switch period {
    case .daily:
      return groupedCounterTotals(index: index, period: .daily, endingOn: date, calendar: calendar)
    case .weekly, .monthly:
      let startOfEndDay = calendar.startOfDay(for: date)
      let dayCount = windowCalendarDayCount(for: period)
      return (0..<dayCount).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfEndDay) else {
          return nil
        }
        return DailyValue(
          date: day,
          value: index.total(onDay: day, calendar: calendar)
        )
      }
      .reversed()
    }
  }

  static func summaryValue(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date,
    perPeriod: Bool,
    activeDaysOnly: Bool,
    calendar: Calendar = .current
  ) -> Double {
    summaryValue(
      index: HistoryEntryIndex(entries: entries, calendar: calendar),
      period: period,
      endingOn: date,
      perPeriod: perPeriod,
      activeDaysOnly: activeDaysOnly,
      calendar: calendar
    )
  }

  static func summaryValue(
    index: HistoryEntryIndex,
    period: HistoryPeriod,
    endingOn date: Date,
    perPeriod: Bool,
    activeDaysOnly: Bool,
    calendar: Calendar = .current
  ) -> Double {
    switch period {
    case .daily:
      return listDailyTotals(index: index, period: .daily, endingOn: date, calendar: calendar)
        .reduce(0) { $0 + $1.value }
    case .weekly, .monthly:
      let dailyTotals = listDailyTotals(
        index: index,
        period: period,
        endingOn: date,
        calendar: calendar
      )
      let total = dailyTotals.reduce(0) { $0 + $1.value }
      guard perPeriod else { return total }
      let denominator: Int
      if activeDaysOnly {
        denominator = dailyTotals.filter { $0.value > 0 }.count
      } else {
        denominator = dailyTotals.count
      }
      guard denominator > 0 else { return 0 }
      return total / Double(denominator)
    }
  }

  static func activeDayCount(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date,
    calendar: Calendar = .current
  ) -> Int {
    let index = HistoryEntryIndex(entries: entries, calendar: calendar)
    let totalDays = windowCalendarDayCount(for: period)
    guard totalDays > 0 else { return 0 }

    let startOfEndDay = calendar.startOfDay(for: date)
    guard let windowStart = calendar.date(byAdding: .day, value: -(totalDays - 1), to: startOfEndDay)
    else { return 0 }

    var count = 0
    for offset in 0..<totalDays {
      guard let day = calendar.date(byAdding: .day, value: offset, to: windowStart) else { continue }
      if index.total(onDay: day, calendar: calendar) > 0 {
        count += 1
      }
    }
    return count
  }

  static func averagePerDay(
    from entries: [CounterEntry],
    period: HistoryPeriod,
    endingOn date: Date,
    activeDaysOnly: Bool,
    calendar: Calendar = .current
  ) -> Double {
    summaryValue(
      from: entries,
      period: period,
      endingOn: date,
      perPeriod: true,
      activeDaysOnly: activeDaysOnly,
      calendar: calendar
    )
  }
}
