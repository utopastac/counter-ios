import AppIntents
import Foundation

struct AddCounterEntryIntent: AppIntent {
  static let title: LocalizedStringResource = "Add Entry"
  static let description = IntentDescription("Log a value to the selected counter.")

  @Parameter(title: "Counter")
  var counterID: String

  @Parameter(title: "Amount")
  var amount: Double

  init() {
    self.counterID = ""
    self.amount = 0
  }

  init(counterID: String, amount: Double) {
    self.counterID = counterID
    self.amount = amount
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    guard amount > 0 else { return .result() }
    let resolvedID = counterID.isEmpty ? WidgetCounterLoader.defaultCounterID() : counterID
    guard let resolvedID else { return .result() }
    WidgetCounterLoader.addEntryQuick(counterID: resolvedID, amount: amount)
    return .result()
  }
}

struct CounterWidgetShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddCounterEntryIntent(counterID: "", amount: 100),
      phrases: [
        "Add to counter in \(.applicationName)",
        "Log counter in \(.applicationName)"
      ],
      shortTitle: "Add in Numo",
      systemImageName: "plus.circle.fill"
    )
  }
}
