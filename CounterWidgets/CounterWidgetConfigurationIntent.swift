import AppIntents
import WidgetKit

struct CounterWidgetConfigurationIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Counter"
  static let description = IntentDescription("Choose which counter this widget displays.")

  @Parameter(title: "Counter")
  var counter: CounterWidgetEntity?
}
