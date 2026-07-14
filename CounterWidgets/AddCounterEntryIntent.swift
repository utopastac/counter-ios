import AppIntents
import Foundation

struct AddCounterEntryIntent: AppIntent {
  static let title: LocalizedStringResource = "Add Entry"
  static let description = IntentDescription("Log a value to the selected counter.")

  @Parameter(title: "Counter")
  var counterID: String

  @Parameter(title: "Amount")
  var amount: Int

  init() {
    self.counterID = WidgetCounterID.calories
    self.amount = 0
  }

  init(counterID: String, amount: Int) {
    self.counterID = counterID
    self.amount = amount
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    guard amount > 0 else { return .result() }
    WidgetCounterLoader.addEntryQuick(counterID: counterID, amount: amount)
    return .result()
  }
}

struct CounterWidgetShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddCounterEntryIntent(counterID: WidgetCounterID.calories, amount: 100),
      phrases: [
        "Add calories in \(.applicationName)",
        "Log calories in \(.applicationName)"
      ],
      shortTitle: "Add Calories",
      systemImageName: "flame.fill"
    )
  }
}
