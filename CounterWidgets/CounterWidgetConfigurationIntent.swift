import AppIntents
import WidgetKit

struct CounterWidgetConfigurationIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Numo"
  static let description = IntentDescription("Choose which Numo counter this widget displays.")

  @Parameter(title: "Counter")
  var counter: CounterWidgetEntity?
}
