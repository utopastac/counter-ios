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

  static func clear() {
    defaults?.removeObject(forKey: Keys.title)
    defaults?.removeObject(forKey: Keys.heroValue)
    defaults?.removeObject(forKey: Keys.updated)
    reloadTimelines()
  }

  static func reloadTimelines() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
  }
}
