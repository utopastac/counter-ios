import Foundation
import SwiftData

@Model
final class CounterEntry {
  var id: UUID
  var value: Double
  var timestamp: Date
  var noteText: String = ""
  /// Path relative to `JournalMediaStore`, empty when the entry has no file.
  var mediaRelativePath: String = ""
  var latitude: Double?
  var longitude: Double?
  var counter: CustomCounter?

  init(value: Double, timestamp: Date = .now, counter: CustomCounter? = nil) {
    self.id = UUID()
    self.value = CounterAmount.rounded(value)
    self.timestamp = timestamp
    self.counter = counter
  }

  var amount: Double {
    get { value }
    set { value = CounterAmount.rounded(newValue) }
  }

  /// Row label for this entry. Number journals show the amount. Other kinds show what was captured.
  var previewText: String {
    switch counter?.kind ?? .number {
    case .number:
      return CounterFormatting.amount(amount)
    case .note:
      let plain = NoteMarkup.plain(noteText)
      return plain.isEmpty ? JournalKind.note.entryNoun : plain
    case .voice:
      return JournalKind.voice.entryNoun
    case .photo:
      return JournalKind.photo.entryNoun
    case .sketch:
      return JournalKind.sketch.entryNoun
    case .place:
      if !noteTitle.isEmpty { return noteTitle }
      if let latitude, let longitude {
        return String(format: "%.4f, %.4f", latitude, longitude)
      }
      return JournalKind.place.entryNoun
    case .book, .movie:
      let noun = counter?.kind.entryNoun ?? JournalKind.book.entryNoun
      return noteTitle.isEmpty ? noun : noteTitle
    }
  }

  /// First line of `noteText`. Books, movies, and places store a title there.
  private var noteTitle: String {
    noteText
      .split(separator: "\n", maxSplits: 1)
      .first
      .map(String.init)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }
}

/// Plain reading of a note stored with lightweight markup (`**bold**`, `*italic*`, `~~strike~~`, `- ` lists).
nonisolated enum NoteMarkup {
  nonisolated static func plain(_ source: String) -> String {
    var text = source
    for marker in ["***", "**", "~~", "*"] {
      text = text.replacingOccurrences(of: marker, with: "")
    }
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
      var value = String(line)
      if value.hasPrefix("- ") {
        value.removeFirst(2)
      }
      return value
    }
    return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
