import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshot {
  private enum Keys {
    static let title = "widget_counter_title"
    static let heroValue = "widget_counter_hero_value"
    static let updated = "widget_counter_updated"
  }

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: AppGroup.identifier)
  }

  static var title: String {
    defaults?.string(forKey: Keys.title) ?? AppGroup.untitledCounterName
  }

  static var heroValue: String {
    defaults?.string(forKey: Keys.heroValue) ?? "0"
  }

  static func publish(title: String, heroValue: String) {
    defaults?.set(title, forKey: Keys.title)
    defaults?.set(heroValue, forKey: Keys.heroValue)
    defaults?.set(Date(), forKey: Keys.updated)
    reloadTimelines()
  }

  static func clear(reloadWidgets: Bool = true) {
    defaults?.removeObject(forKey: Keys.title)
    defaults?.removeObject(forKey: Keys.heroValue)
    defaults?.removeObject(forKey: Keys.updated)
    if reloadWidgets {
      reloadTimelines()
    }
  }

  static func reloadTimelines() {
    #if canImport(WidgetKit)
    // Hostless `CounterTests` is an `.xctest` bundle — calling `WidgetCenter` from there
    // while SwiftData is mid-mutation (or when reloads overlap across tests) can trap the
    // process. Production targets are always `.app` / `.appex`.
    let path = Bundle.main.bundlePath
    guard path.hasSuffix(".app") || path.hasSuffix(".appex") else { return }

    // Defer so callers can finish SwiftData saves before the widget extension opens the store.
    DispatchQueue.main.async {
      WidgetCenter.shared.reloadAllTimelines()
    }
    #endif
  }
}
