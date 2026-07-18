import Foundation
import Testing

struct HistoryAggregatorTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()

  private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 12,
    minute: Int = 0
  ) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
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

  @Test func groupedCounterTotalsDailyReturnsTwentyFourHourlyBuckets() {
    let endDate = date(2026, 7, 14, 12)
    let entries = [
      CounterEntry(value: 10, timestamp: date(2026, 7, 14, 8)),
      CounterEntry(value: 5, timestamp: date(2026, 7, 14, 8, minute: 30)),
      CounterEntry(value: 20, timestamp: date(2026, 7, 14, 15)),
      CounterEntry(value: 100, timestamp: date(2026, 7, 13, 8)) // other day — ignored
    ]

    let grouped = HistoryAggregator.groupedCounterTotals(
      from: entries,
      period: .daily,
      endingOn: endDate,
      calendar: calendar
    )

    #expect(grouped.count == 24)
    #expect(calendar.component(.hour, from: grouped[0].date) == 0)
    #expect(calendar.component(.hour, from: grouped[23].date) == 23)
    #expect(grouped[8].value == 15)
    #expect(grouped[15].value == 20)
    #expect(grouped.filter { $0.value > 0 }.count == 2)
  }

  @Test func bucketRangeDailyIsOneHour() {
    let range = HistoryAggregator.bucketRange(
      for: date(2026, 7, 14, 8),
      period: .daily,
      calendar: calendar
    )
    #expect(calendar.isDate(range.start, equalTo: date(2026, 7, 14, 8), toGranularity: .hour))
    #expect(calendar.isDate(range.end, equalTo: date(2026, 7, 14, 9), toGranularity: .hour))
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

  @Test func maxWindowOffsetUsesBrowseableMinimumWithoutEntries() {
    #expect(HistoryAggregator.maxWindowOffset(from: [], period: .daily, relativeTo: date(2026, 7, 14)) == 51)
  }

  @Test func maxWindowOffsetKeepsBrowseableMinimumForRecentEntries() {
    let entries = [CounterEntry(value: 10, timestamp: date(2026, 7, 1, 12))]
    #expect(
      HistoryAggregator.maxWindowOffset(
        from: entries,
        period: .daily,
        relativeTo: date(2026, 7, 14, 12)
      ) == 51
    )
  }

  @Test func maxWindowOffsetExpandsPastBrowseableMinimumForOldEntries() {
    let entries = [CounterEntry(value: 10, timestamp: date(2024, 7, 14, 12))]
    let offset = HistoryAggregator.maxWindowOffset(
      from: entries,
      period: .daily,
      relativeTo: date(2026, 7, 14, 12),
      calendar: calendar
    )
    #expect(offset > 51)
  }

  @Test func endingDateShiftsByWindowStep() {
    let end = HistoryAggregator.endingDate(
      forWindowOffset: 1,
      period: .daily,
      relativeTo: date(2026, 7, 14, 12),
      calendar: calendar
    )
    #expect(calendar.isDate(end, inSameDayAs: date(2026, 7, 13, 12)))
  }
}
