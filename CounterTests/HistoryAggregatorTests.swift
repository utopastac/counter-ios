import Foundation
import Testing

struct HistoryAggregatorTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }

  @Test func counterTotalSumsEntriesOnTheSameCalendarDay() {
    // `HistoryAggregator.counterTotal` compares calendar days using `Calendar.current`
    // (the device/test-runner's local time zone), so entries are kept close to local
    // noon to stay on the same calendar day regardless of the machine's UTC offset.
    let entries = [
      CounterEntry(value: 10, timestamp: date(2026, 7, 14, 11)),
      CounterEntry(value: 5, timestamp: date(2026, 7, 14, 13)),
      CounterEntry(value: 100, timestamp: date(2026, 7, 13, 12))
    ]

    let total = HistoryAggregator.counterTotal(from: entries, on: date(2026, 7, 14, 12))
    #expect(total == 15)
  }

  @Test func groupedCounterTotalsDailyReturnsOneEntryPerDayInAscendingOrder() {
    let endDate = date(2026, 7, 14, 12)
    let entries = [
      CounterEntry(value: 10, timestamp: date(2026, 7, 14, 8)),
      CounterEntry(value: 20, timestamp: date(2026, 7, 13, 8))
    ]

    let grouped = HistoryAggregator.groupedCounterTotals(from: entries, period: .daily, endingOn: endDate)

    #expect(grouped.count == HistoryPeriod.daily.dayCount)
    // Ascending order: earliest day first, ending day last.
    #expect(grouped.first!.date < grouped.last!.date)
    #expect(grouped.last!.value == 10)
    #expect(grouped[grouped.count - 2].value == 20)
  }

  @Test func groupedCounterTotalsWeeklyBucketsSevenDayWindows() {
    let endDate = date(2026, 7, 14, 12)
    let entries = [
      CounterEntry(value: 7, timestamp: date(2026, 7, 14, 8)),
      CounterEntry(value: 3, timestamp: date(2026, 7, 8, 8)) // one week back from endDate
    ]

    let grouped = HistoryAggregator.groupedCounterTotals(from: entries, period: .weekly, endingOn: endDate)

    #expect(grouped.count == HistoryPeriod.weekly.dayCount)
    let total = grouped.reduce(0) { $0 + $1.value }
    #expect(total == 10)
  }

  @Test func groupedCounterTotalsMonthlyReturnsThirtyDailyBuckets() {
    let grouped = HistoryAggregator.groupedCounterTotals(from: [], period: .monthly, endingOn: date(2026, 7, 14, 12))
    #expect(grouped.count == HistoryPeriod.monthly.dayCount)
  }
}
