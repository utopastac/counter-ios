import Foundation

/// Opens the main app on a specific counter from a home-screen / Lock Screen widget tap.
enum CounterDeepLink {
  static let scheme = "numo"
  static let counterHost = "counter"

  static func url(counterID: String) -> URL? {
    guard !counterID.isEmpty, UUID(uuidString: counterID) != nil else { return nil }
    var components = URLComponents()
    components.scheme = scheme
    components.host = counterHost
    components.path = "/\(counterID)"
    return components.url
  }

  static func counterID(from url: URL) -> UUID? {
    guard url.scheme == scheme, url.host == counterHost else { return nil }
    let idString = url.path.split(separator: "/").first.map(String.init)
    guard let idString, let id = UUID(uuidString: idString) else { return nil }
    return id
  }
}
