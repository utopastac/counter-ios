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

/// Paragraph styles stored as Markdown ATX prefixes, matching Notes: Title, Heading, Subheading, Body.
nonisolated enum NoteParagraphStyle: String, CaseIterable, Identifiable, Sendable {
  case title
  case heading
  case subheading
  case body

  var id: String { rawValue }

  var label: String {
    switch self {
    case .title: "Title"
    case .heading: "Heading"
    case .subheading: "Subheading"
    case .body: "Body"
    }
  }

  var markdownPrefix: String {
    switch self {
    case .title: "# "
    case .heading: "## "
    case .subheading: "### "
    case .body: ""
    }
  }

  /// Removes one leading heading marker from a single line.
  static func strippingPrefix(_ line: String) -> (style: NoteParagraphStyle, text: String) {
    if line.hasPrefix("### ") { return (.subheading, String(line.dropFirst(4))) }
    if line.hasPrefix("## ") { return (.heading, String(line.dropFirst(3))) }
    if line.hasPrefix("# ") { return (.title, String(line.dropFirst(2))) }
    return (.body, line)
  }
}

/// Return-key behavior for note lists and headings, matching the Notes app.
nonisolated enum NoteListEditing {
  enum ReturnAction: Equatable {
    /// The caret is in a list item that has text. Insert another bullet.
    case continueList
    /// The list item is empty. Remove the bullet and leave a normal line.
    case exitList
    /// Return in a heading starts the next paragraph as body text.
    case breakHeading
    case passthrough
  }

  static let listMarker = "- "

  static func returnAction(lineContent: String, style: NoteParagraphStyle) -> ReturnAction {
    if lineContent.hasPrefix(listMarker) {
      let body = String(lineContent.dropFirst(listMarker.count))
      if body.trimmingCharacters(in: .whitespaces).isEmpty {
        return .exitList
      }
      return .continueList
    }
    if style != .body {
      return .breakHeading
    }
    return .passthrough
  }
}

/// Plain reading of a note stored with lightweight markup (`**bold**`, `*italic*`, `~~strike~~`, `# ` headings, `- ` lists).
nonisolated enum NoteMarkup {
  nonisolated static func plain(_ source: String) -> String {
    var text = source
    for marker in ["***", "**", "~~", "*"] {
      text = text.replacingOccurrences(of: marker, with: "")
    }
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
      var value = NoteParagraphStyle.strippingPrefix(String(line)).text
      if value.hasPrefix(NoteListEditing.listMarker) {
        value.removeFirst(NoteListEditing.listMarker.count)
      }
      return value
    }
    return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
