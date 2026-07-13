import WidgetKit
import SwiftUI

struct CounterComplicationEntry: TimelineEntry {
  let date: Date
  let added: Int
  let burned: Int

  var net: Int { added - burned }
}

struct CounterComplicationProvider: TimelineProvider {
  func placeholder(in context: Context) -> CounterComplicationEntry {
    CounterComplicationEntry(date: .now, added: 1200, burned: 1800)
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
      added: WidgetSnapshot.added,
      burned: WidgetSnapshot.burned
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
    .description("Today's calorie balance.")
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
      Text("\(entry.net)")
    }
  }

  private var circularView: some View {
    VStack(spacing: 0) {
      Image(systemName: "flame.fill")
        .font(.caption2)
      Text(formattedNet(entry.net))
        .font(.system(.body, design: .rounded, weight: .semibold))
        .minimumScaleFactor(0.6)
    }
  }

  private var rectangularView: some View {
    VStack(alignment: .leading, spacing: 2) {
      Label("Counter", systemImage: "flame.fill")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text("+\(entry.added) added")
        .font(.caption2)
      Text("-\(entry.burned) burned")
        .font(.caption2)
      Text("Net \(formattedNet(entry.net))")
        .font(.caption.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var inlineView: some View {
    Text("Net \(formattedNet(entry.net)) kcal")
  }

  private var cornerView: some View {
    Text(formattedNet(entry.net))
      .font(.system(.title3, design: .rounded, weight: .bold))
  }

  private func formattedNet(_ value: Int) -> String {
    value >= 0 ? "+\(value)" : "\(value)"
  }
}

#Preview(as: .accessoryCircular) {
  CounterComplicationWidget()
} timeline: {
  CounterComplicationEntry(date: .now, added: 1450, burned: 2100)
}

#Preview(as: .accessoryRectangular) {
  CounterComplicationWidget()
} timeline: {
  CounterComplicationEntry(date: .now, added: 1450, burned: 2100)
}
