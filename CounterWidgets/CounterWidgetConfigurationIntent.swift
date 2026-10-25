import AppIntents
import WidgetKit

struct CounterWidgetConfigurationIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Dayring"
  static let description = IntentDescription("Choose which Dayring counter this widget displays.")

  @Parameter(title: "Counter")
  var counter: CounterWidgetEntity?
}
