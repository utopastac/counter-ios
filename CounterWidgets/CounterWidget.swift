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
    .description("Show a total and quick-add from your home or Lock Screen.")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .systemLarge,
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline
    ])
    .contentMarginsDisabled()
  }
}

struct CounterWidgetContainer: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetFamily) private var family
  let entry: CounterWidgetEntry

  private var isAccessoryFamily: Bool {
    switch family {
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      true
    default:
      false
    }
  }

  var body: some View {
    CounterWidgetView(entry: entry)
      .containerBackground(for: .widget) {
        if isAccessoryFamily {
          AccessoryWidgetBackground()
        } else {
          Rectangle().fill(
            WidgetThemeColors(
              paletteIndex: entry.snapshot.paletteIndex,
              colorScheme: colorScheme
            ).backgroundStyle
          )
        }
      }
      .modifier(CounterWidgetOpenURLModifier(counterID: entry.counter.id, isUnavailable: entry.snapshot.isUnavailable))
  }
}

/// Opens the main app on this counter when the user taps non-interactive widget chrome.
private struct CounterWidgetOpenURLModifier: ViewModifier {
  let counterID: String
  let isUnavailable: Bool

  func body(content: Content) -> some View {
    if !isUnavailable, let url = CounterDeepLink.url(counterID: counterID) {
      content.widgetURL(url)
    } else {
      content
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

  private func progressRing(
    progress: GoalProgress,
    size: CGFloat = WidgetTheme.ringSize,
    trackColor: Color? = nil,
    fillColor: Color? = nil,
    overfillOutlineColor: Color? = nil
  ) -> some View {
    WidgetGoalProgressRing(
      progress: progress,
      trackColor: trackColor ?? colors.ringTrack,
      fillColor: fillColor ?? colors.foreground,
      overfillOutlineColor: overfillOutlineColor ?? colors.ringOverfillOutline,
      size: size,
      ringWidthOverride: entry.snapshot.progressRingWidth,
      ringGlowOverride: entry.snapshot.progressRingGlowEnabled
    )
  }

  var body: some View {
    if entry.snapshot.isUnavailable {
      unavailableLayout
    } else {
      switch family {
      case .systemMedium:
        mediumLayout
      case .systemLarge:
        largeLayout
      case .accessoryCircular:
        accessoryCircularLayout
      case .accessoryRectangular:
        accessoryRectangularLayout
      case .accessoryInline:
        accessoryInlineLayout
      default:
        smallLayout
      }
    }
  }

  /// Minimal copy when the configured counter was deleted — no ring, totals, or quick-add.
  private var unavailableLayout: some View {
    Group {
      switch family {
      case .accessoryCircular:
        Image(systemName: "minus.circle")
          .font(.title2)
      case .accessoryInline:
        Text(entry.snapshot.title)
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 2) {
          Text(entry.snapshot.title)
            .font(.caption2)
          Text(entry.snapshot.heroSubtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      default:
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
    }
  }

  private var smallLayout: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Ring sits above the text stack on the leading edge — title, hero, and subtitle each
      // keep their own line below it (unlike medium, which places the ring beside a combined
      // heading to free vertical space for quick-add buttons).
      if let ringProgress = entry.snapshot.ringProgress {
        progressRing(progress: ringProgress)
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

      quickAddGrid
        .padding(.top, WidgetTheme.headerToQuickAddSpacing)
        .layoutPriority(0)

      Spacer(minLength: 0)
    }
    .padding(homeScreenMargins)
  }

  private var largeLayout: some View {
    VStack(alignment: .leading, spacing: 0) {
      mediumHeader

      quickAddGrid
        .padding(.top, WidgetTheme.headerToQuickAddSpacing)

      Spacer(minLength: WidgetTheme.largeQuickAddToEntriesSpacing)

      if !entry.snapshot.recentEntries.isEmpty {
        WidgetRecentEntriesList(
          entries: entry.snapshot.recentEntries,
          colors: colors
        )
      }
    }
    .padding(homeScreenMargins)
  }

  /// Same insets for medium and large so family-specific `widgetContentMargins` can't
  /// change the header's available width (and thus its `minimumScaleFactor` sizing).
  private var homeScreenMargins: EdgeInsets {
    EdgeInsets(
      top: WidgetTheme.homeScreenContentMargin,
      leading: WidgetTheme.homeScreenContentMargin,
      bottom: WidgetTheme.homeScreenContentMargin,
      trailing: WidgetTheme.homeScreenContentMargin
    )
  }

  private var accessoryCircularLayout: some View {
    ZStack {
      if let ringProgress = entry.snapshot.ringProgress {
        progressRing(
          progress: ringProgress,
          size: WidgetTheme.accessoryRingSize,
          trackColor: .secondary.opacity(0.35),
          fillColor: .primary,
          overfillOutlineColor: .clear
        )
      }
      Text(entry.snapshot.heroValue)
        .font(WidgetTheme.packFont(size: 12))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
  }

  private var accessoryRectangularLayout: some View {
    HStack(alignment: .center, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.counter.title)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(entry.snapshot.heroValue)
          .font(WidgetTheme.packFont(size: 17))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Text(entry.snapshot.heroSubtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let ringProgress = entry.snapshot.ringProgress {
        progressRing(
          progress: ringProgress,
          size: 28,
          trackColor: .secondary.opacity(0.35),
          fillColor: .primary,
          overfillOutlineColor: .clear
        )
      }
    }
  }

  private var accessoryInlineLayout: some View {
    Text("\(entry.counter.title) \(entry.snapshot.heroValue)")
  }

  /// Hero heading + subtitle on the leading edge, ring on the trailing edge — matches the
  /// main app's pager header (`CounterPageHeader` in `Counter/Views/Pager/CounterPageLayout.swift`).
  ///
  /// `fixedSize` + `layoutPriority` keep this at its ideal height so a tight medium widget
  /// can't vertically compress the hero text (which would otherwise shrink via
  /// `minimumScaleFactor` and make the large widget's header look bigger by comparison).
  private var mediumHeader: some View {
    HStack(alignment: .top, spacing: 12) {
      WidgetHeroHeading(
        heroValue: entry.snapshot.heroValue,
        title: entry.counter.title,
        subtitle: entry.snapshot.heroSubtitle,
        foreground: colors.foreground
      )

      if let ringProgress = entry.snapshot.ringProgress {
        progressRing(progress: ringProgress)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .layoutPriority(1)
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

#Preview(as: .systemLarge) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "preview", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .placeholder
  )
}

#Preview(as: .accessoryCircular) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "preview", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .placeholder
  )
}

#Preview(as: .accessoryRectangular) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: "preview", title: "Calories", paletteIndex: 0, sortOrder: 0),
    snapshot: .placeholder
  )
}
