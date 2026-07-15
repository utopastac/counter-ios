import Foundation

nonisolated enum CounterResetPeriod: String, Codable, CaseIterable, Identifiable {
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

  /// Formats a day-of-month as an ordinal string (e.g. `1` → `"1st"`, `22` → `"22nd"`).
  ///
  /// Shared by the monthly "resets on" picker and any other UI that needs to
  /// describe a specific day of the month.
  static func ordinalDay(_ day: Int) -> String {
    let suffix: String
    switch day % 10 {
    case 1 where day % 100 != 11: suffix = "st"
    case 2 where day % 100 != 12: suffix = "nd"
    case 3 where day % 100 != 13: suffix = "rd"
    default: suffix = "th"
    }
    return "\(day)\(suffix)"
  }

  /// The anchor day this period should start from when there's no existing anchor worth
  /// preserving (e.g. a brand-new counter). Weekly defaults to the calendar's first weekday;
  /// daily and monthly both default to `1`.
  func defaultAnchorDay(calendar: Calendar = .current) -> Int {
    switch self {
    case .daily: return 1
    case .weekly: return calendar.firstWeekday
    case .monthly: return 1
    }
  }

  /// Coerces `currentAnchorDay` when switching *into* this period on an already-configured
  /// counter: keeps it unchanged if it's still valid for the new period, and only falls back
  /// to `defaultAnchorDay` when it's out of range (e.g. a monthly anchor of `30` isn't a valid
  /// weekday). Anchors aren't comparable across period types, so this is "keep if valid,
  /// default otherwise" rather than "always keep" or "always reset".
  func normalizedAnchorDay(_ currentAnchorDay: Int, calendar: Calendar = .current) -> Int {
    switch self {
    case .daily:
      return 1
    case .weekly:
      return (1...7).contains(currentAnchorDay) ? currentAnchorDay : calendar.firstWeekday
    case .monthly:
      return (1...28).contains(currentAnchorDay) ? currentAnchorDay : 1
    }
  }
}

nonisolated struct CounterPeriodRange {
  let start: Date
  let end: Date
}

nonisolated enum CounterPeriodCalculator {
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

  /// `counter`'s own entries, filtered to its current period and sorted newest-first — the
  /// convention every entry log/preview in the app uses. Centralized so "current period,
  /// newest first" can't quietly diverge into a different order at a new call site.
  static func currentEntries(
    for counter: CustomCounter,
    on date: Date = .now,
    calendar: Calendar = .current
  ) -> [CounterEntry] {
    let range = currentRange(for: counter, on: date, calendar: calendar)
    return entries(from: counter.entries, in: range).sorted { $0.timestamp > $1.timestamp }
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
