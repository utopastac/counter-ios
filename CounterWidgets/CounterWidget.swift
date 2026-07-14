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
        id: WidgetCounterID.calories,
        title: "Calories",
        paletteIndex: 0
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
    let resolved = counter ?? CounterWidgetEntity(
      id: WidgetCounterID.calories,
      title: "Calories",
      paletteIndex: 0
    )
    return CounterWidgetEntry(
      date: .now,
      counter: resolved,
      snapshot: WidgetCounterLoader.snapshot(for: resolved.id)
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
    .configurationDisplayName("Counter")
    .description("Track a counter and quick-add from your home screen.")
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
  let entry: CounterWidgetEntry

  private var colors: WidgetThemeColors {
    WidgetThemeColors(paletteIndex: entry.snapshot.paletteIndex, colorScheme: colorScheme)
  }

  var body: some View {
    switch family {
    case .systemMedium:
      mediumLayout
    default:
      smallLayout
    }
  }

  private var smallLayout: some View {
    VStack(alignment: .leading, spacing: 6) {
      labelText(entry.snapshot.title)
      heroText(size: 44)
      labelText(entry.snapshot.heroCaption.capitalized)
    }
    .foregroundStyle(colors.foreground)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(16)
  }

  private var mediumLayout: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          labelText(entry.snapshot.title)
          heroText(size: 40)
          labelText(entry.snapshot.heroCaption.capitalized)
        }

        Spacer(minLength: 0)

        WidgetProgressRing(
          fraction: entry.snapshot.ringFraction,
          foreground: colors.foreground,
          size: 54,
          lineWidth: 12
        )
      }

      Spacer(minLength: 12)

      quickAddGrid
    }
    .padding(16)
  }

  private func labelText(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 13, weight: .medium, design: .rounded))
      .foregroundStyle(colors.mutedForeground)
  }

  private func heroText(size: CGFloat) -> some View {
    Text(entry.snapshot.heroValue)
      .font(.system(size: size, weight: .bold, design: .rounded))
      .foregroundStyle(colors.foreground)
      .minimumScaleFactor(0.55)
      .lineLimit(1)
      .contentTransition(.numericText())
  }

  @ViewBuilder
  private var quickAddGrid: some View {
    let values = entry.snapshot.buttonValues
    let firstRowCount = min(5, values.count)
    let firstRow = Array(values.prefix(firstRowCount))
    let secondRow = Array(values.dropFirst(firstRowCount))
    let columns = Array(
      repeating: GridItem(.flexible(), spacing: WidgetTheme.buttonSpacing),
      count: 5
    )

    LazyVGrid(columns: columns, spacing: WidgetTheme.buttonSpacing) {
      ForEach(firstRow, id: \.self) { value in
        WidgetQuickAddButton(counter: entry.counter, value: value, colors: colors)
          .frame(height: WidgetTheme.buttonHeight)
      }

      ForEach(secondRow, id: \.self) { value in
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
    counter: CounterWidgetEntity(id: WidgetCounterID.calories, title: "Calories", paletteIndex: 0),
    snapshot: .placeholder
  )
}

#Preview(as: .systemMedium) {
  CounterWidget()
} timeline: {
  CounterWidgetEntry(
    date: .now,
    counter: CounterWidgetEntity(id: WidgetCounterID.calories, title: "Calories", paletteIndex: 0),
    snapshot: .placeholder
  )
}
