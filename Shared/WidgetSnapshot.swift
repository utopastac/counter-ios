import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshot {
  private enum Keys {
    static let added = "widget_calories_added"
    static let burned = "widget_calories_burned"
    static let updated = "widget_calories_updated"
  }

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: AppGroup.identifier)
  }

  static var added: Int {
    defaults?.integer(forKey: Keys.added) ?? 0
  }

  static var burned: Int {
    defaults?.integer(forKey: Keys.burned) ?? 0
  }

  static var net: Int {
    added - burned
  }

  static var lastUpdated: Date? {
    defaults?.object(forKey: Keys.updated) as? Date
  }

  static func publish(added: Int, burned: Int) {
    defaults?.set(added, forKey: Keys.added)
    defaults?.set(burned, forKey: Keys.burned)
    defaults?.set(Date(), forKey: Keys.updated)
    reloadTimelines()
  }

  static func reloadTimelines() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
  }
}
