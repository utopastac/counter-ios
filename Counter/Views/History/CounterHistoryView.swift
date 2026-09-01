import SwiftUI

struct CounterHistoryView: View {
  let counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.semanticColors) private var colors
  @State private var period: HistoryPeriod = .daily
  @State private var windowOffset = 0
  @State private var selectedBucket: DailyValue?
  @AppStorage(AppAppearancePreference.historyAverageActiveDaysOnlyKey)
  private var isHistoryAverageActiveDaysOnlyEnabled = false
  @AppStorage(AppAppearancePreference.historyPerPeriodEnabledKey)
  private var isHistoryPerPeriodEnabled = true

  private var maxWindowOffset: Int {
    HistoryAggregator.maxWindowOffset(from: counter.entries, period: period)
  }

  private var windowEndingDate: Date {
    HistoryAggregator.endingDate(forWindowOffset: windowOffset, period: period)
  }

  private var chartData: [DailyValue] {
    dataForOffset(windowOffset)
  }

  private var listDailyData: [DailyValue] {
    HistoryAggregator.listDailyTotals(
      from: counter.entries,
      period: period,
      endingOn: windowEndingDate
    )
  }

  private var listItems: [HistoryListItem] {
    let items = listDailyData.reversed().map { item in
      HistoryListItem(date: item.date, value: item.value)
    }
    if period == .daily {
      return items.filter { $0.value > 0 }
    }
    return items
  }

  private var listDateFormat: Date.FormatStyle {
    switch period {
    case .daily:
      return .dateTime.hour().minute()
    case .weekly, .monthly:
      return .dateTime.weekday(.abbreviated).month(.abbreviated).day(.twoDigits)
    }
  }

  private var perPeriodEnabled: Bool {
    counter.overrideHistoryPerPeriod ?? isHistoryPerPeriodEnabled
  }

  private var averageActiveDaysOnly: Bool {
    counter.overrideHistoryAverageActiveDaysOnly ?? isHistoryAverageActiveDaysOnlyEnabled
  }

  private var windowSummaryValue: Double {
    HistoryAggregator.summaryValue(
      from: counter.entries,
      period: period,
      endingOn: windowEndingDate,
      perPeriod: perPeriodEnabled,
      activeDaysOnly: averageActiveDaysOnly
    )
  }

  private var windowDatePrimaryLabel: String {
    windowEndingDate.formatted(.dateTime.month(.wide).day(.twoDigits))
  }

  private var windowDateYearLabel: String {
    windowEndingDate.formatted(.dateTime.year())
  }

  private var windowSummaryAmount: String {
    CounterFormatting.amount(windowSummaryValue)
  }

  private var windowSummaryCaption: String {
    switch period {
    case .daily:
      return "total"
    case .weekly, .monthly:
      guard perPeriodEnabled else { return "total" }
      if averageActiveDaysOnly {
        return "per active day"
      }
      return "per day"
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(
        title: "\(counter.name) history",
        onDone: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: HistoryToken.sectionSpacing) {
          HistoryPeriodPicker(selection: $period)

          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: SpaceToken.x1) {
              Text(windowDatePrimaryLabel)
                .counterTextStyle(.sectionTitle, compact: true)

              Text(windowDateYearLabel)
                .counterTextStyle(.caption, color: .secondary, compact: true)
            }

            Spacer(minLength: SpaceToken.u2)

            VStack(alignment: .trailing, spacing: SpaceToken.x1) {
              Text(windowSummaryAmount)
                .counterTextStyle(.historyListValue, compact: true)

              Text(windowSummaryCaption)
                .counterTextStyle(.caption, color: .secondary, compact: true)
            }
          }

          HistoryBarChart(
            period: period,
            windowOffset: $windowOffset,
            maxWindowOffset: maxWindowOffset,
            dataForOffset: dataForOffset,
            onSelectBar: { selectedBucket = $0 }
          )
          .counterAccent(.forCounter(counter))

          if !listItems.isEmpty {
            HistoryList(items: listItems, dateFormat: listDateFormat) { item in
              selectedBucket = DailyValue(date: item.date, value: item.value)
            }
          }
        }
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u1)
        .padding(.bottom, SpaceToken.u4)
      }
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromColorScheme()
    .counterSheetPresentation()
    .onChange(of: period) { _, _ in
      windowOffset = 0
    }
    .onChange(of: maxWindowOffset) { _, newMax in
      if windowOffset > newMax {
        windowOffset = newMax
      }
    }
    .sheet(item: $selectedBucket) { bucket in
      bucketEntrySheet(for: bucket)
    }
  }

  private func dataForOffset(_ offset: Int) -> [DailyValue] {
    HistoryAggregator.groupedCounterTotals(
      from: counter.entries,
      period: period,
      endingOn: HistoryAggregator.endingDate(forWindowOffset: offset, period: period)
    )
  }

  private func bucketEntrySheet(for bucket: DailyValue) -> some View {
    let bucketPeriod: HistoryPeriod = period == .daily ? .daily : .monthly
    let range = HistoryAggregator.bucketRange(for: bucket.date, period: bucketPeriod)
    let entries = CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
    let title = bucketSheetTitle(for: bucket.date, bucketPeriod: bucketPeriod)

    return NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: title,
          onDone: { selectedBucket = nil }
        )

        CounterPeriodEntryLogContent(
          entries: entries,
          emptyDescription: "No entries in this period.",
          onDelete: { id in
            EntryActions.deleteCounterEntry(id: id, in: modelContext)
            WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          },
          onValueCommit: { id, value in
            EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
            WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          }
        )
      }
      .background(colors.surfaceSheet)
      .counterDesignSystemFromColorScheme()
      .counterSheetPresentation()
    }
  }

  private func bucketSheetTitle(for date: Date, bucketPeriod: HistoryPeriod) -> String {
    switch bucketPeriod {
    case .daily:
      return date.formatted(.dateTime.hour().minute())
    case .monthly:
      return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day(.twoDigits))
    case .weekly:
      let range = HistoryAggregator.bucketRange(for: date, period: .weekly)
      let format = Date.FormatStyle().month(.abbreviated).day(.twoDigits)
      return "\(range.start.formatted(format)) – \(date.formatted(format))"
    }
  }
}


#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Calories"))
}
