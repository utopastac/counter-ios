import WidgetKit
import SwiftUI

struct CounterWidgetEntry: TimelineEntry {
  let date: Date
  let counter: CounterWidgetEntity
  let snapshot: CounterWidgetSnapshot
}

struct CounterWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CounterWidgetEntry {
    CounterWidgetEntry(
      date: .now,
      counter: CounterWidgetEntity(
        id: "preview",
        title: "Calories",
        paletteIndex: 0,
        sortOrder: 0
      ),
      snapshot: .placeholder
    )
  }

  func snapshot(for configuration: CounterWidgetConfigurationIntent, in context: Context) async -> CounterWidgetEntry {
    currentEntry(for: configuration.counter)
  }

  func timeline(
    for configuration: CounterWidgetConfigurationIntent,
    in context: Context
  ) async -> Timeline<CounterWidgetEntry> {
    let entry = currentEntry(for: configuration.counter)
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)
      ?? .now.addingTimeInterval(900)
    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }

  private func currentEntry(for counter: CounterWidgetEntity?) -> CounterWidgetEntry {
    guard let counter else {
      // Unconfigured, or WidgetKit cleared a deleted selection — never use the gallery
      // "preview" placeholder here (that path always looks like a live Calories counter).
      return CounterWidgetEntry(
        date: .now,
        counter: CounterWidgetEntity(
          id: "",
          title: "Counter removed",
          paletteIndex: 0,
          sortOrder: 0
        ),
        snapshot: .unavailable
      )
    }

    return CounterWidgetEntry(
      date: .now,
      counter: counter,
      snapshot: WidgetCounterLoader.snapshot(for: counter.id)
    )
  }
}

struct CounterWidget: Widget {
  let kind = "CounterWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: CounterWidgetConfigurationIntent.self,
      provider: CounterWidgetProvider()
    ) { entry in
      CounterWidgetContainer(entry: entry)
    }
    .configurationDisplayName("Numo")
    .description("Show a total and quick-add from your home screen.")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}

struct CounterWidgetContainer: View {
  @Environment(\.colorScheme) private var colorScheme
  let entry: CounterWidgetEntry

  var body: some View {
    CounterWidgetView(entry: entry)
      .containerBackground(for: .widget) {
        WidgetThemeColors(
          paletteIndex: entry.snapshot.paletteIndex,
          colorScheme: colorScheme
        ).background
      }
  }
}

struct CounterWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetContentMargins) private var widgetMargins
  let entry: CounterWidgetEntry

  private var colors: WidgetThemeColors {
    WidgetThemeColors(paletteIndex: entry.snapshot.paletteIndex, colorScheme: colorScheme)
  }

  var body: some View {
    if entry.snapshot.isUnavailable {
      unavailableLayout
    } else {
      switch family {
      case .systemMedium:
        mediumLayout
      default:
        smallLayout
      }
    }
  }

  /// Minimal copy when the configured counter was deleted — no ring, totals, or quick-add.
  private var unavailableLayout: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(entry.snapshot.title)
        .font(WidgetTheme.smallTitleFont)
        .tracking(WidgetTheme.smallTitleTracking)
        .foregroundStyle(colors.foreground)
        .lineLimit(2)
        .minimumScaleFactor(0.8)

      Text(entry.snapshot.heroSubtitle)
        .font(WidgetTheme.smallSubtitleFont)
        .tracking(WidgetTheme.smallSubtitleTracking)
        .foregroundStyle(colors.foreground.opacity(0.7))
        .lineLimit(3)
        .minimumScaleFactor(0.8)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(widgetMargins)
  }

  private var smallLayout: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Ring sits above the text stack on the leading edge — title, hero, and subtitle each
      // keep their own line below it (unlike medium, which places the ring beside a combined
      // heading to free vertical space for quick-add buttons).
      if let ringProgress = entry.snapshot.ringProgress {
        WidgetGoalProgressRing(
          progress: ringProgress,
          trackColor: colors.ringTrack,
          fillColor: colors.foreground,
          overfillOutlineColor: colors.ringOverfillOutline
        )
        .padding(.bottom, WidgetTheme.smallRingToTitleSpacing)
      }

      WidgetSmallHeroStack(
        title: entry.counter.title,
        heroValue: entry.snapshot.heroValue,
        subtitle: entry.snapshot.heroSubtitle,
        foreground: colors.foreground
      )
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(widgetMargins)
  }

  private var mediumLayout: some View {
    VStack(alignment: .leading, spacing: 0) {
      mediumHeader

      Spacer(minLength: 12)

      quickAddGrid
    }
    .padding(widgetMargins)
  }

  /// Hero heading + subtitle on the leading edge, ring on the trailing edge — matches the
  /// main app's pager header (`CounterPageHeader` in `Counter/Views/Pager/CounterPageLayout.swift`).
  private var mediumHeader: some View {
    HStack(alignment: .top, spacing: 12) {
      WidgetHeroHeading(
        heroValue: entry.snapshot.heroValue,
        title: entry.counter.title,
        subtitle: entry.snapshot.heroSubtitle,
        foreground: colors.foreground
      )

      if let ringProgress = entry.snapshot.ringProgress {
        WidgetGoalProgressRing(
          progress: ringProgress,
          trackColor: colors.ringTrack,
          fillColor: colors.foreground,
          overfillOutlineColor: colors.ringOverfillOutline
        )
      }
    }
  }

  @ViewBuilder
  private var quickAddGrid: some View {
    let values = Array(entry.snapshot.buttonValues.prefix(8))
    let columns = Array(
      repeating: GridItem(.flexible(), spacing: WidgetTheme.buttonSpacing),
      count: WidgetTheme.buttonColumns
    )

    LazyVGrid(columns: columns, spacing: WidgetTheme.buttonSpacing) {
      ForEach(values, id: \.self) { value in
        WidgetQuickAddButton(counter: entry.counter, value: value, colors: colors)
          .frame(height: WidgetTheme.buttonHeight)
      }
    }
  }
}

#Preview(as: .systemSmall) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "preview", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .placeholder
  )
}

#Preview("Unavailable", as: .systemSmall) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "missing", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .unavailable
  )
}

#Preview(as: .systemMedium) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "preview", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .placeholder
  )
}

#Preview("Unavailable", as: .systemMedium) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "missing", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .unavailable
  )
}
