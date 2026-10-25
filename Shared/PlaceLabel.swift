import Foundation

/// Title and locality stored on a place entry. The title line is what history shows.
nonisolated enum PlaceLabel {
  /// Venue name when it differs from the street. Otherwise the street, then the city.
  /// The second line is the street and city, skipping anything already used as the title.
  static func stored(name: String, street: String, city: String) -> String {
    let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let street = street.trimmingCharacters(in: .whitespacesAndNewlines)
    let city = city.trimmingCharacters(in: .whitespacesAndNewlines)

    let venue = name.isEmpty || same(name, street) ? "" : name
    let title = if !venue.isEmpty {
      venue
    } else if !street.isEmpty {
      street
    } else {
      city
    }
    guard !title.isEmpty else { return "" }

    let subtitle = if !venue.isEmpty {
      streetLine(street, city: city, title: title)
    } else if !city.isEmpty, !same(city, title) {
      city
    } else {
      ""
    }
    guard !subtitle.isEmpty else { return title }
    return "\(title)\n\(subtitle)"
  }

  private static func streetLine(_ street: String, city: String, title: String) -> String {
    let street = same(street, title) ? "" : street
    let city = city.isEmpty || same(city, title) || contains(street, city) ? "" : city
    return [street, city].filter { !$0.isEmpty }.joined(separator: ", ")
  }

  private static func contains(_ street: String, _ city: String) -> Bool {
    street.localizedCaseInsensitiveContains(city)
  }

  private static func same(_ lhs: String, _ rhs: String) -> Bool {
    lhs.caseInsensitiveCompare(rhs) == .orderedSame
  }
}
