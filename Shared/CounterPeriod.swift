import Foundation

enum CounterResetPeriod: String, Codable, CaseIterable, Identifiable {
  case daily
  case weekly
  case monthly

  var id: String { rawValue }

  var label: String {
    switch self {
    case .daily: "Daily"
    case .weekly: "Weekly"
    case .monthly: "Monthly"
    }
  }

  var periodCaption: String {
    switch self {
    case .daily: "today"
    case .weekly: "this week"
    case .monthly: "this month"
    }
  }
}

struct CounterPeriodRange {
  let start: Date
  let end: Date
}

enum CounterPeriodCalculator {
  static func currentRange(
    for counter: CustomCounter,
    on date: Date = .now,
    calendar: Calendar = .current
  ) -> CounterPeriodRange {
    currentRange(
      resetPeriod: counter.resetPeriod,
      resetAnchorDay: counter.effectiveResetAnchorDay,
      on: date,
      calendar: calendar
    )
  }

  static func currentRange(
    resetPeriod: CounterResetPeriod,
    resetAnchorDay: Int,
    on date: Date = .now,
    calendar: Calendar = .current
  ) -> CounterPeriodRange {
    switch resetPeriod {
    case .daily:
      let start = calendar.startOfDay(for: date)
      let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
      return CounterPeriodRange(start: start, end: end)

    case .weekly:
      let weekday = calendar.component(.weekday, from: date)
      let anchor = resetAnchorDay
      var daysBack = weekday - anchor
      if daysBack < 0 { daysBack += 7 }
      let startDay = calendar.date(byAdding: .day, value: -daysBack, to: date) ?? date
      let start = calendar.startOfDay(for: startDay)
      let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
      return CounterPeriodRange(start: start, end: end)

    case .monthly:
      let anchorDay = resetAnchorDay
      let day = calendar.component(.day, from: date)
      var monthComponents = calendar.dateComponents([.year, .month], from: date)

      if day >= clampedAnchorDay(anchorDay, for: monthComponents, calendar: calendar) {
        monthComponents.day = clampedAnchorDay(anchorDay, for: monthComponents, calendar: calendar)
        let start = calendar.startOfDay(for: calendar.date(from: monthComponents) ?? date)
        var nextMonth = monthComponents
        nextMonth.month = (nextMonth.month ?? 1) + 1
        nextMonth.day = clampedAnchorDay(anchorDay, for: nextMonth, calendar: calendar)
        let end = calendar.startOfDay(for: calendar.date(from: nextMonth) ?? start)
        return CounterPeriodRange(start: start, end: end)
      }

      monthComponents.month = (monthComponents.month ?? 1) - 1
      monthComponents.day = clampedAnchorDay(anchorDay, for: monthComponents, calendar: calendar)
      let start = calendar.startOfDay(for: calendar.date(from: monthComponents) ?? date)

      var currentMonth = calendar.dateComponents([.year, .month], from: date)
      currentMonth.day = clampedAnchorDay(anchorDay, for: currentMonth, calendar: calendar)
      let end = calendar.startOfDay(for: calendar.date(from: currentMonth) ?? start)
      return CounterPeriodRange(start: start, end: end)
    }
  }

  static func resetSummary(for counter: CustomCounter, calendar: Calendar = .current) -> String {
    resetSummary(
      resetPeriod: counter.resetPeriod,
      resetAnchorDay: counter.effectiveResetAnchorDay,
      calendar: calendar
    )
  }

  static func resetSummary(
    resetPeriod: CounterResetPeriod,
    resetAnchorDay: Int,
    calendar: Calendar = .current
  ) -> String {
    switch resetPeriod {
    case .daily:
      return "Resets daily at midnight"
    case .weekly:
      let index = max(0, min(resetAnchorDay - 1, calendar.weekdaySymbols.count - 1))
      return "Resets weekly on \(calendar.weekdaySymbols[index])"
    case .monthly:
      return "Resets monthly on day \(resetAnchorDay)"
    }
  }

  static func entries(
    from allEntries: [CounterEntry],
    in range: CounterPeriodRange
  ) -> [CounterEntry] {
    allEntries.filter { $0.timestamp >= range.start && $0.timestamp < range.end }
  }

  static func total(
    from allEntries: [CounterEntry],
    for counter: CustomCounter,
    on date: Date = .now,
    calendar: Calendar = .current
  ) -> Int {
    let range = currentRange(for: counter, on: date, calendar: calendar)
    return entries(from: allEntries, in: range).reduce(0) { $0 + $1.value }
  }

  private static func clampedAnchorDay(
    _ anchorDay: Int,
    for components: DateComponents,
    calendar: Calendar
  ) -> Int {
    guard
      let year = components.year,
      let month = components.month,
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
      let dayRange = calendar.range(of: .day, in: .month, for: date)
    else {
      return min(max(anchorDay, 1), 28)
    }

    return min(max(anchorDay, 1), dayRange.count)
  }
}
