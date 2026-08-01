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

  private var maxWindowOffset: Int {
    HistoryAggregator.maxWindowOffset(from: counter.entries, period: period)
  }

  private var chartData: [DailyValue] {
    dataForOffset(windowOffset)
  }

  private var listItems: [HistoryListItem] {
    let items = chartData.reversed().map { item in
      HistoryListItem(date: item.date, value: item.value)
    }
    // Day view has 24 hour buckets — only list hours that have activity.
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
      return Date.FormatStyle().month(.abbreviated).day(.twoDigits)
    }
  }

  private var windowRangeLabel: String {
    let day = HistoryAggregator.endingDate(forWindowOffset: windowOffset, period: period)
    return day.formatted(.dateTime.month(.wide).day(.twoDigits).year())
  }

  private var averageActiveDaysOnly: Bool {
    counter.overrideHistoryAverageActiveDaysOnly ?? isHistoryAverageActiveDaysOnlyEnabled
  }

  private var windowTotal: Double {
    chartData.reduce(0) { $0 + $1.value }
  }

  private var windowSummaryValue: Double {
    switch period {
    case .daily:
      return windowTotal
    case .weekly, .monthly:
      return HistoryAggregator.averagePerDay(
        from: counter.entries,
        period: period,
        endingOn: HistoryAggregator.endingDate(forWindowOffset: windowOffset, period: period),
        activeDaysOnly: averageActiveDaysOnly
      )
    }
  }

  private var windowSummaryLabel: String {
    let amount = CounterFormatting.amount(windowSummaryValue)
    switch period {
    case .daily:
      return "\(amount) total"
    case .weekly, .monthly:
      if averageActiveDaysOnly {
        return "\(amount) per active day"
      }
      return "\(amount) per day"
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

          if !windowRangeLabel.isEmpty {
            HStack(alignment: .firstTextBaseline) {
              Text(windowRangeLabel)
                .counterTextStyle(.sectionTitle, compact: true)

              Spacer(minLength: SpaceToken.u2)

              Text(windowSummaryLabel)
                .counterTextStyle(.sectionTitle, compact: true)
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
    let range = HistoryAggregator.bucketRange(for: bucket.date, period: period)
    let entries = CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
    let title = bucketSheetTitle(for: bucket.date)

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

  private func bucketSheetTitle(for date: Date) -> String {
    switch period {
    case .daily:
      return date.formatted(.dateTime.hour().minute())
    case .weekly:
      let range = HistoryAggregator.bucketRange(for: date, period: period)
      let format = Date.FormatStyle().month(.abbreviated).day(.twoDigits)
      return "\(range.start.formatted(format)) – \(date.formatted(format))"
    case .monthly:
      return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day(.twoDigits))
    }
  }
}


#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Calories"))
}
