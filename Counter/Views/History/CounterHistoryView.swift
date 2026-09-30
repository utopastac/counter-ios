import SwiftUI

struct CounterHistoryView: View {
  let counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var period: HistoryPeriod = .daily
  @State private var windowOffset = 0
  @State private var selectedBucket: DailyValue?
  @State private var editingEntry: HistoryEditingEntry?
  @State private var entryIndex: HistoryEntryIndex
  @AppStorage(AppAppearancePreference.historyAverageActiveDaysOnlyKey)
  private var isHistoryAverageActiveDaysOnlyEnabled = false
  @AppStorage(AppAppearancePreference.historyPerPeriodEnabledKey)
  private var isHistoryPerPeriodEnabled = true

  init(counter: CustomCounter) {
    self.counter = counter
    _entryIndex = State(initialValue: HistoryEntryIndex(entries: counter.entries))
  }

  private var maxWindowOffset: Int {
    HistoryAggregator.maxWindowOffset(
      earliestTimestamp: entryIndex.earliestTimestamp,
      period: period
    )
  }

  private var windowEndingDate: Date {
    HistoryAggregator.endingDate(forWindowOffset: windowOffset, period: period)
  }

  private var listDailyData: [DailyValue] {
    HistoryAggregator.listDailyTotals(
      index: entryIndex,
      period: period,
      endingOn: windowEndingDate
    )
  }

  private var listItems: [HistoryListItem] {
    listDailyData.reversed().map { item in
      HistoryListItem(date: item.date, value: item.value)
    }
  }

  private var dayEntries: [CounterEntry] {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: windowEndingDate)
    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
    return CounterPeriodCalculator.entries(
      from: counter.entries,
      in: CounterPeriodRange(start: start, end: end)
    )
    .sorted { $0.timestamp > $1.timestamp }
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
      index: entryIndex,
      period: period,
      endingOn: windowEndingDate,
      perPeriod: perPeriodEnabled,
      activeDaysOnly: averageActiveDaysOnly
    )
  }

  private var windowDateRange: (start: Date, end: Date) {
    let calendar = Calendar.current
    let end = calendar.startOfDay(for: windowEndingDate)
    let dayCount = HistoryAggregator.windowCalendarDayCount(for: period)
    let start = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) ?? end
    return (start, end)
  }

  private var windowDatePrimaryLabel: String {
    switch period {
    case .daily:
      return windowEndingDate.formatted(.dateTime.month(.wide).day(.twoDigits))
    case .weekly, .monthly:
      let range = windowDateRange
      let format = Date.FormatStyle().month(.abbreviated).day(.twoDigits)
      return "\(range.start.formatted(format)) – \(range.end.formatted(format))"
    }
  }

  private var windowDateYearLabel: String {
    switch period {
    case .daily:
      return windowEndingDate.formatted(.dateTime.year())
    case .weekly, .monthly:
      let range = windowDateRange
      let calendar = Calendar.current
      let startYear = calendar.component(.year, from: range.start)
      let endYear = calendar.component(.year, from: range.end)
      if startYear == endYear {
        return range.end.formatted(.dateTime.year())
      }
      return "\(startYear) – \(endYear)"
    }
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
    NavigationStack {
      VStack(spacing: 0) {
        CounterSheetHeader(
          title: "\(counter.name) history",
          onDone: { dismiss() }
        )

        List {
          Section {
            historyChrome
              .listRowInsets(EdgeInsets(
                top: SpaceToken.u2,
                leading: SheetToken.horizontal,
                bottom: HistoryToken.sectionSpacing,
                trailing: SheetToken.horizontal
              ))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }

          if period == .daily {
            dayEntryRows
          } else if !listItems.isEmpty {
            aggregateRows
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectHidden(true, for: .top)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .toolbar(.hidden, for: .navigationBar)
      .navigationDestination(item: $selectedBucket) { bucket in
        HistoryBucketDetailView(
          counter: counter,
          bucket: bucket,
          period: period,
          onBack: { selectedBucket = nil },
          onEntriesChanged: refreshEntryIndex
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
    .onChange(of: period) { _, _ in
      windowOffset = 0
      selectedBucket = nil
    }
    .onChange(of: maxWindowOffset) { _, newMax in
      if windowOffset > newMax {
        windowOffset = newMax
      }
    }
    .sheet(item: $editingEntry) { entry in
      EditAmountSheet(initialValue: entry.value) { newValue in
        updateEntry(id: entry.id, value: newValue)
      }
    }
  }

  private var historyChrome: some View {
    VStack(alignment: .leading, spacing: HistoryToken.sectionSpacing) {
      HistoryPeriodPicker(selection: $period)

      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: SpaceToken.x1) {
          Text(windowDatePrimaryLabel)
            .counterTextStyle(.historyListValue, compact: true)

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
        entryIndex: entryIndex,
        period: period,
        windowOffset: $windowOffset,
        maxWindowOffset: maxWindowOffset,
        onSelectBar: { selectedBucket = $0 }
      )
    }
  }

  @ViewBuilder
  private var dayEntryRows: some View {
    ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in
      VStack(spacing: 0) {
        if index > 0 {
          SettingsDivider()
        }

        EntryLogEditableRow(
          value: entry.amount,
          timestamp: entry.timestamp,
          dateFormat: listDateFormat,
          onEdit: {
            editingEntry = HistoryEditingEntry(id: entry.id, value: entry.amount)
          }
        )
      }
      .listRowInsets(EdgeInsets(
        top: 0,
        leading: SheetToken.horizontal,
        bottom: 0,
        trailing: SheetToken.horizontal
      ))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) {
          deleteEntry(id: entry.id)
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
  }

  @ViewBuilder
  private var aggregateRows: some View {
    ForEach(Array(listItems.enumerated()), id: \.element.id) { index, item in
      VStack(spacing: 0) {
        if index > 0 {
          SettingsDivider()
        }

        CounterValueDateRow(
          valueText: CounterFormatting.amount(item.value),
          date: item.date,
          dateFormat: listDateFormat,
          onTap: {
            selectedBucket = DailyValue(date: item.date, value: item.value)
          }
        )
      }
      .listRowInsets(EdgeInsets(
        top: 0,
        leading: SheetToken.horizontal,
        bottom: 0,
        trailing: SheetToken.horizontal
      ))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
    }
  }

  private func deleteEntry(id: UUID) {
    EntryActions.deleteCounterEntry(id: id, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
    refreshEntryIndex()
  }

  private func updateEntry(id: UUID, value: Double) {
    EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
    refreshEntryIndex()
  }

  private func refreshEntryIndex() {
    entryIndex = HistoryEntryIndex(entries: counter.entries)
  }
}

/// Pushed bucket drill-in inside the history sheet (not a nested modal).
private struct HistoryBucketDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.semanticColors) private var colors

  let counter: CustomCounter
  let bucket: DailyValue
  let period: HistoryPeriod
  let onBack: () -> Void
  let onEntriesChanged: () -> Void

  private var bucketPeriod: HistoryPeriod {
    period == .daily ? .daily : .monthly
  }

  private var entries: [CounterEntry] {
    let range = HistoryAggregator.bucketRange(for: bucket.date, period: bucketPeriod)
    return CounterPeriodCalculator.entries(from: counter.entries, in: range)
      .sorted { $0.timestamp > $1.timestamp }
  }

  private var title: String {
    switch bucketPeriod {
    case .daily:
      return bucket.date.formatted(.dateTime.hour().minute())
    case .monthly:
      return bucket.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day(.twoDigits))
    case .weekly:
      let range = HistoryAggregator.bucketRange(for: bucket.date, period: .weekly)
      let format = Date.FormatStyle().month(.abbreviated).day(.twoDigits)
      return "\(range.start.formatted(format)) – \(bucket.date.formatted(format))"
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      bucketHeader

      CounterPeriodEntryLogContent(
        entries: entries,
        emptyDescription: "No entries in this period.",
        onDelete: { id in
          EntryActions.deleteCounterEntry(id: id, in: modelContext)
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          onEntriesChanged()
        },
        onValueCommit: { id, value in
          EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
          WidgetSnapshotSync.publish(counter: counter, in: modelContext)
          onEntriesChanged()
        }
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var bucketHeader: some View {
    HStack(alignment: .center, spacing: SpaceToken.x1) {
      Button {
        CounterKeyboard.resign()
        onBack()
      } label: {
        CounterLucideIcon(icon: .arrowLeft, color: colors.textPrimary)
          .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
          .frame(
            width: SizeToken.iconButtonHitArea,
            height: SizeToken.iconButtonHitArea,
            alignment: .leading
          )
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Back")

      Text(title)
        .counterTextStyle(.sheetTitle)
        .lineLimit(1)

      Spacer(minLength: 0)
    }
    .padding(.leading, SpaceToken.u1)
    .padding(.trailing, SheetToken.horizontal)
    .padding(.top, SpaceToken.u2)
    .padding(.bottom, SpaceToken.u1)
  }
}

private struct HistoryEditingEntry: Identifiable, Equatable {
  let id: UUID
  let value: Double
}

#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Calories"))
}
