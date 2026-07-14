import WidgetKit
import SwiftUI

struct CounterComplicationEntry: TimelineEntry {
  let date: Date
  let title: String
  let heroValue: String
}

struct CounterComplicationProvider: TimelineProvider {
  func placeholder(in context: Context) -> CounterComplicationEntry {
    CounterComplicationEntry(date: .now, title: "Counter", heroValue: "1200")
  }

  func getSnapshot(in context: Context, completion: @escaping (CounterComplicationEntry) -> Void) {
    completion(currentEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CounterComplicationEntry>) -> Void) {
    let entry = currentEntry()
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
  }

  private func currentEntry() -> CounterComplicationEntry {
    CounterComplicationEntry(
      date: .now,
      title: WidgetSnapshot.title,
      heroValue: WidgetSnapshot.heroValue
    )
  }
}

struct CounterComplicationWidget: Widget {
  let kind = "CounterComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CounterComplicationProvider()) { entry in
      CounterComplicationView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Counter")
    .description("Shows your default counter total.")
    .supportedFamilies([
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline,
      .accessoryCorner
    ])
  }
}

struct CounterComplicationView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CounterComplicationEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      circularView
    case .accessoryRectangular:
      rectangularView
    case .accessoryInline:
      inlineView
    case .accessoryCorner:
      cornerView
    default:
      Text(entry.heroValue)
    }
  }

  private var circularView: some View {
    VStack(spacing: 0) {
      Image(systemName: "number.square.fill")
        .font(.caption2)
      Text(entry.heroValue)
        .font(.system(.body, design: .rounded, weight: .semibold))
        .minimumScaleFactor(0.6)
    }
  }

  private var rectangularView: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label(entry.title, systemImage: "number.square.fill")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(entry.heroValue)
        .font(.caption.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var inlineView: some View {
    Text("\(entry.title) \(entry.heroValue)")
  }

  private var cornerView: some View {
    Text(entry.heroValue)
      .font(.system(.title3, design: .rounded, weight: .bold))
  }
}

#Preview(as: .accessoryCircular) {
  CounterComplicationWidget()
} timeline: {
  CounterComplicationEntry(date: .now, title: "Calories", heroValue: "1450")
}

#Preview(as: .accessoryRectangular) {
  CounterComplicationWidget()
} timeline: {
  CounterComplicationEntry(date: .now, title: "Calories", heroValue: "1450")
}
