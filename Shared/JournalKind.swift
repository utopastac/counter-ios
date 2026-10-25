import Foundation

/// What a journal records. Number journals keep quick-add totals. Every other kind
/// records one entry at a time. The cap is the ring's target, and entries can pass it.
nonisolated enum JournalKind: String, Codable, CaseIterable, Identifiable, Sendable {
  case number
  case note
  case voice
  case photo
  case sketch
  case place
  case book
  case movie

  var id: String { rawValue }

  var label: String {
    switch self {
    case .number: "Number"
    case .note: "Note"
    case .voice: "Voice"
    case .photo: "Photos"
    case .sketch: "Sketches"
    case .place: "Places"
    case .book: "Books"
    case .movie: "Movies"
    }
  }

  /// Noun used in toasts and entry rows ("Note added").
  var entryNoun: String {
    switch self {
    case .number: "Entry"
    case .voice: "Voice note"
    case .note: "Note"
    case .photo: "Photo"
    case .sketch: "Sketch"
    case .place: "Place"
    case .book: "Book"
    case .movie: "Movie"
    }
  }

  var defaultName: String {
    switch self {
    case .number: "Count"
    case .note: "Note"
    case .voice: "Voice"
    case .photo: "Photos"
    case .sketch: "Sketches"
    case .place: "Places"
    case .book: "Books"
    case .movie: "Movies"
    }
  }

  /// Starting cap for a new journal of this kind. Number journals can still be saved with none.
  var defaultCap: Double {
    switch self {
    case .number: 10
    case .note, .voice, .place: 1
    case .photo, .sketch, .book, .movie: 3
    }
  }

  var requiresCap: Bool {
    self != .number
  }

  /// Newest entries shown on the counter page. History lists the whole period.
  var counterPagePreviewCount: Int {
    switch self {
    case .note, .voice, .place: 3
    case .photo, .sketch: 6
    case .number, .book, .movie: 5
    }
  }
}
