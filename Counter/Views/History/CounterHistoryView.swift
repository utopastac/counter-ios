import SwiftUI

struct CounterHistoryView: View {
  let counter: CustomCounter

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.semanticColors) private var colors
  @Environment(\.colorScheme) private var colorScheme
  @State private var period: HistoryPeriod = .daily
  @State private var windowOffset = 0
  @State private var presentedSheet: HistoryPresentedSheet?
  @State private var entryIndex: HistoryEntryIndex
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(AppAppearancePreference.historyAverageActiveDaysOnlyKey)
  private var isHistoryAverageActiveDaysOnlyEnabled = false
  @AppStorage(AppAppearancePreference.historyPerPeriodEnabledKey)
  private var isHistoryPerPeriodEnabled = true

  init(counter: CustomCounter) {
    self.counter = counter
    _entryIndex = State(initialValue: HistoryEntryIndex(entries: counter.entries))
  }

  private var pageAccent: CounterAccent {
    let _ = (isMonoEnabled, monoPaletteIndex, isTintEnabled, colorPackRaw)
    return .forCounter(counter)
  }

  private var palette: CounterPaletteSlot {
    pageAccent.palette
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
    ZStack(alignment: .top) {
      Rectangle()
        .fill(palette.backgroundStyle(for: colorScheme))
        .ignoresSafeArea()

      List {
        Section {
          historyChrome
            .listRowInsets(EdgeInsets(
              top: SpaceToken.u1,
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
      .safeAreaPadding(.top, SpaceToken.pageTopInset)

      historyToolbar
    }
    .counterAccent(pageAccent)
    .counterDesignSystemFromColorScheme()
    .toolbar(.hidden, for: .navigationBar)
    .navigationBarBackButtonHidden()
    .onChange(of: period) { _, _ in
      windowOffset = 0
    }
    .onChange(of: maxWindowOffset) { _, newMax in
      if windowOffset > newMax {
        windowOffset = newMax
      }
    }
    .sheet(item: $presentedSheet) { sheet in
      switch sheet {
      case .bucket(let bucket):
        bucketEntrySheet(for: bucket)
      case .editEntry(let entryID, let value):
        EditAmountSheet(initialValue: value) { newValue in
          updateEntry(id: entryID, value: newValue)
        }
      }
    }
  }

  /// One clear glass layer, full-bleed under the status bar. Rounded/`safeAreaBar`
  /// chrome made this a floating frosted pill — the pager avoids that by clipping
  /// its glass to the counter card.
  private var historyToolbar: some View {
    HStack(spacing: SpaceToken.toolbarIconSpacing) {
      Text("\(counter.name) history")
        .counterTextStyle(.pageTitle)
        .lineLimit(1)

      Spacer(minLength: 0)

      Button("Done") {
        CounterKeyboard.resign()
        dismiss()
      }
      .counterTextStyle(.settingsRowLabel)
      .buttonStyle(.plain)
      .padding(.horizontal, SpaceToken.u2)
      .frame(height: SizeToken.iconButtonHitArea)
      .contentShape(Rectangle())
    }
    .padding(.horizontal, SheetToken.horizontal)
    .frame(maxWidth: .infinity)
    .frame(minHeight: SizeToken.iconButtonHitArea)
    .background {
      Rectangle()
        .fill(.clear)
        .glassEffect(
          .clear.tint(palette.background(for: colorScheme)).interactive(),
          in: .rect(cornerRadius: 0)
        )
        .ignoresSafeArea(edges: .top)
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
        onSelectBar: { presentedSheet = .bucket($0) }
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
            presentedSheet = .editEntry(id: entry.id, value: entry.amount)
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
            presentedSheet = .bucket(DailyValue(date: item.date, value: item.value))
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
    entryIndex = HistoryEntryIndex(entries: counter.entries)
  }

  private func updateEntry(id: UUID, value: Double) {
    EntryActions.updateCounterEntry(id: id, value: value, in: modelContext)
    WidgetSnapshotSync.publish(counter: counter, in: modelContext)
    entryIndex = HistoryEntryIndex(entries: counter.entries)
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
          onDone: { presentedSheet = nil }
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

private enum HistoryPresentedSheet: Identifiable, Equatable {
  case bucket(DailyValue)
  case editEntry(id: UUID, value: Double)

  var id: String {
    switch self {
    case .bucket(let bucket):
      "bucket-\(bucket.date.timeIntervalSinceReferenceDate)"
    case .editEntry(let id, _):
      "edit-\(id.uuidString)"
    }
  }
}


#Preview {
  CounterHistoryView(counter: CustomCounter(name: "Calories"))
}
