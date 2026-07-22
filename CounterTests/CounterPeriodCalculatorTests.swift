import Foundation
import Testing

struct CounterPeriodCalculatorTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }

  // MARK: - Daily

  @Test func dailyRangeIsCalendarDay() {
    let now = date(2026, 7, 14, 15)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .daily,
      resetAnchorDay: 1,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 7, 14, 0))
    #expect(range.end == date(2026, 7, 15, 0))
  }

  // MARK: - Weekly

  @Test func weeklyRangeStartsOnAnchorWeekday() {
    // 2026-07-14 is a Tuesday. Anchor weekday 2 = Monday (calendar weekday index).
    let now = date(2026, 7, 14, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .weekly,
      resetAnchorDay: 2,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 7, 13, 0))
    #expect(range.end == date(2026, 7, 20, 0))
  }

  @Test func weeklyRangeWrapsBackwardAcrossWeekBoundary() {
    // Anchor weekday 6 = Friday. From a Tuesday, the most recent Friday is 4 days back.
    let now = date(2026, 7, 14, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .weekly,
      resetAnchorDay: 6,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 7, 10, 0))
    #expect(range.end == date(2026, 7, 17, 0))
  }

  // MARK: - Monthly

  @Test func monthlyRangeBeforeAnchorDayUsesPreviousMonth() {
    let now = date(2026, 7, 5, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .monthly,
      resetAnchorDay: 15,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 6, 15, 0))
    #expect(range.end == date(2026, 7, 15, 0))
  }

  @Test func monthlyRangeOnOrAfterAnchorDayUsesCurrentMonth() {
    let now = date(2026, 7, 20, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .monthly,
      resetAnchorDay: 15,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 7, 15, 0))
    #expect(range.end == date(2026, 8, 15, 0))
  }

  @Test func monthlyRangeClampsAnchorDayToShortMonth() {
    // February (non-leap 2026) only has 28 days; anchor day 30 clamps to 28.
    let now = date(2026, 2, 27, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .monthly,
      resetAnchorDay: 30,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 1, 30, 0) || range.start == date(2026, 1, 31, 0))
    #expect(range.end == date(2026, 2, 28, 0))
  }

  // MARK: - Yearly

  @Test func yearlyRangeBeforeAnchorMonthUsesPreviousYear() {
    // Anchor month 3 = March. From February, the period started last March.
    let now = date(2026, 2, 14, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .yearly,
      resetAnchorDay: 3,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2025, 3, 1, 0))
    #expect(range.end == date(2026, 3, 1, 0))
  }

  @Test func yearlyRangeOnOrAfterAnchorMonthUsesCurrentYear() {
    let now = date(2026, 7, 14, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .yearly,
      resetAnchorDay: 3,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 3, 1, 0))
    #expect(range.end == date(2027, 3, 1, 0))
  }

  @Test func yearlyRangeDefaultsToJanuaryWhenAnchorIsOne() {
    let now = date(2026, 7, 14, 9)
    let range = CounterPeriodCalculator.currentRange(
      resetPeriod: .yearly,
      resetAnchorDay: 1,
      on: now,
      calendar: calendar
    )

    #expect(range.start == date(2026, 1, 1, 0))
    #expect(range.end == date(2027, 1, 1, 0))
  }

  // MARK: - resetSummary

  @Test func resetSummaryDescribesEachPeriod() {
    #expect(
      CounterPeriodCalculator.resetSummary(resetPeriod: .daily, resetAnchorDay: 1, calendar: calendar)
        == "Resets daily at midnight"
    )
    #expect(
      CounterPeriodCalculator.resetSummary(resetPeriod: .monthly, resetAnchorDay: 15, calendar: calendar)
        == "Resets monthly on day 15"
    )
    let weekly = CounterPeriodCalculator.resetSummary(resetPeriod: .weekly, resetAnchorDay: 2, calendar: calendar)
    #expect(weekly.hasPrefix("Resets weekly on"))
    let yearly = CounterPeriodCalculator.resetSummary(resetPeriod: .yearly, resetAnchorDay: 1, calendar: calendar)
    #expect(yearly.hasPrefix("Resets yearly in"))
  }

  // MARK: - total

  @Test func totalSumsOnlyEntriesWithinRange() {
    let counter = CustomCounter(name: "Water", resetPeriod: .daily)
    let inRange = CounterEntry(value: 10, timestamp: date(2026, 7, 14, 8))
    let alsoInRange = CounterEntry(value: 5, timestamp: date(2026, 7, 14, 20))
    let outOfRange = CounterEntry(value: 100, timestamp: date(2026, 7, 13, 23))

    let total = CounterPeriodCalculator.total(
      from: [inRange, alsoInRange, outOfRange],
      for: counter,
      on: date(2026, 7, 14, 12),
      calendar: calendar
    )

    #expect(total == 15)
  }

  /// Regression test for a real bug: the watch counter list previously used
  /// `HistoryAggregator.counterTotal(..., on: .now)` (calendar day) while the detail
  /// view used `CounterPeriodCalculator.total` (reset period), so the two disagreed
  /// for any non-daily counter. This asserts the two calculations actually diverge
  /// for a weekly counter, which is why the list view was switched to the period total.
  @Test func periodTotalDiffersFromCalendarDayTotalForAWeeklyCounter() {
    let counter = CustomCounter(name: "Steps", resetPeriod: .weekly, resetAnchorDay: 2)
    let today = date(2026, 7, 14, 12) // Tuesday
    let entries = [
      CounterEntry(value: 10, timestamp: today),
      CounterEntry(value: 20, timestamp: date(2026, 7, 13, 12)) // earlier this week, not "today"
    ]

    let periodTotal = CounterPeriodCalculator.total(from: entries, for: counter, on: today, calendar: calendar)
    let calendarDayTotal = HistoryAggregator.counterTotal(from: entries, on: today)

    #expect(periodTotal == 30)
    #expect(calendarDayTotal == 10)
    #expect(periodTotal != calendarDayTotal)
  }

  @Test func ordinalDayFormatsSuffixesCorrectly() {
    #expect(CounterResetPeriod.ordinalDay(1) == "1st")
    #expect(CounterResetPeriod.ordinalDay(2) == "2nd")
    #expect(CounterResetPeriod.ordinalDay(3) == "3rd")
    #expect(CounterResetPeriod.ordinalDay(4) == "4th")
    #expect(CounterResetPeriod.ordinalDay(11) == "11th")
    #expect(CounterResetPeriod.ordinalDay(12) == "12th")
    #expect(CounterResetPeriod.ordinalDay(13) == "13th")
    #expect(CounterResetPeriod.ordinalDay(21) == "21st")
    #expect(CounterResetPeriod.ordinalDay(22) == "22nd")
    #expect(CounterResetPeriod.ordinalDay(23) == "23rd")
  }

  // MARK: - defaultAnchorDay

  @Test func defaultAnchorDayIsOneForDailyMonthlyAndYearly() {
    #expect(CounterResetPeriod.daily.defaultAnchorDay(calendar: calendar) == 1)
    #expect(CounterResetPeriod.monthly.defaultAnchorDay(calendar: calendar) == 1)
    #expect(CounterResetPeriod.yearly.defaultAnchorDay(calendar: calendar) == 1)
  }

  @Test func defaultAnchorDayIsTheCalendarsFirstWeekdayForWeekly() {
    #expect(CounterResetPeriod.weekly.defaultAnchorDay(calendar: calendar) == calendar.firstWeekday)
  }

  // MARK: - normalizedAnchorDay

  @Test func normalizedAnchorDayAlwaysCollapsesToOneForDaily() {
    #expect(CounterResetPeriod.daily.normalizedAnchorDay(5, calendar: calendar) == 1)
  }

  @Test func normalizedAnchorDayPreservesAnAlreadyValidWeeklyAnchor() {
    #expect(CounterResetPeriod.weekly.normalizedAnchorDay(3, calendar: calendar) == 3)
  }

  @Test func normalizedAnchorDayFallsBackToFirstWeekdayForAnOutOfRangeWeeklyAnchor() {
    #expect(CounterResetPeriod.weekly.normalizedAnchorDay(30, calendar: calendar) == calendar.firstWeekday)
  }

  @Test func normalizedAnchorDayPreservesAnAlreadyValidMonthlyAnchor() {
    #expect(CounterResetPeriod.monthly.normalizedAnchorDay(15, calendar: calendar) == 15)
  }

  @Test func normalizedAnchorDayFallsBackToOneForAnOutOfRangeMonthlyAnchor() {
    #expect(CounterResetPeriod.monthly.normalizedAnchorDay(30, calendar: calendar) == 1)
  }

  @Test func normalizedAnchorDayPreservesAnAlreadyValidYearlyAnchor() {
    #expect(CounterResetPeriod.yearly.normalizedAnchorDay(6, calendar: calendar) == 6)
  }

  @Test func normalizedAnchorDayFallsBackToOneForAnOutOfRangeYearlyAnchor() {
    #expect(CounterResetPeriod.yearly.normalizedAnchorDay(15, calendar: calendar) == 1)
  }

  // MARK: - currentEntries

  @Test func currentEntriesReturnsOnlyThisPeriodsEntriesNewestFirst() {
    let counter = CustomCounter(name: "Water", resetPeriod: .daily)
    let older = CounterEntry(value: 10, timestamp: date(2026, 7, 14, 8))
    let newer = CounterEntry(value: 5, timestamp: date(2026, 7, 14, 20))
    let outOfRange = CounterEntry(value: 100, timestamp: date(2026, 7, 13, 23))
    counter.entries = [older, newer, outOfRange]

    let entries = CounterPeriodCalculator.currentEntries(for: counter, on: date(2026, 7, 14, 12), calendar: calendar)

    #expect(entries.map(\.amount) == [5, 10])
  }
}
