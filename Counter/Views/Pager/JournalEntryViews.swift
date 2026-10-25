import AVFoundation
import SwiftUI
import UIKit

enum JournalMediaMetrics {
  static let frame: CGFloat = GridToken.units(18)
  static let historyHeight: CGFloat = GridToken.units(22)
  static let record: CGFloat = GridToken.units(10)
  static let recordLarge: CGFloat = GridToken.units(16)
  static let writingHeight: CGFloat = GridToken.units(12)
}

enum JournalClock {
  static func string(from seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

@MainActor
enum VoiceClipDuration {
  private static var cache: [String: String] = [:]

  static func label(for relativePath: String) async -> String {
    if let cached = cache[relativePath] { return cached }
    guard let url = JournalMediaStore.fileURL(relativePath: relativePath) else { return "" }
    let asset = AVURLAsset(url: url)
    guard let duration = try? await asset.load(.duration) else { return "" }
    let seconds = CMTimeGetSeconds(duration)
    guard seconds.isFinite, seconds > 0 else { return "" }
    let label = JournalClock.string(from: seconds)
    cache[relativePath] = label
    return label
  }
}

@MainActor
@Observable
final class VoicePlayback: NSObject, AVAudioPlayerDelegate {
  static let shared = VoicePlayback()

  private var player: AVAudioPlayer?
  private(set) var playingID: UUID?

  func toggle(entryID: UUID, relativePath: String) {
    if playingID == entryID {
      stop()
      return
    }
    stop()
    guard let url = JournalMediaStore.fileURL(relativePath: relativePath) else { return }
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default)
    try? session.setActive(true)
    guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
    player.delegate = self
    player.play()
    self.player = player
    playingID = entryID
  }

  func stop() {
    player?.stop()
    player = nil
    playingID = nil
  }

  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      guard self.player === player else { return }
      self.player = nil
      self.playingID = nil
    }
  }
}

struct JournalMediaImage: View {
  let relativePath: String

  @State private var image: UIImage?

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Color.clear
      }
    }
    .task(id: relativePath) {
      guard let url = JournalMediaStore.fileURL(relativePath: relativePath) else {
        image = nil
        return
      }
      let full = UIImage(contentsOfFile: url.path)
      image = full?.preparingThumbnail(of: CGSize(width: 800, height: 800)) ?? full
    }
  }
}

struct JournalMediaStrip: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  let entries: [CounterEntry]
  var showsAdd: Bool
  var addLabel: String
  var entryLabel: String
  let onAdd: () -> Void
  let onDelete: (UUID) -> Void

  private var columns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: SpaceToken.u1), count: 3)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: SpaceToken.u1) {
      if showsAdd {
        Button {
          guard !counterRevealIsDragging else { return }
          onAdd()
        } label: {
          Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
              CounterLucideIcon(icon: .plus, color: colors.textPrimary)
            }
            .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
            .overlay {
              RadiusToken.continuousListCard
                .strokeBorder(colors.borderSubtle, lineWidth: BorderToken.settingsDivider)
            }
        }
        .buttonStyle(.noHighlight)
        .accessibilityLabel(addLabel)
      }

      ForEach(entries) { entry in
        Color.clear
          .aspectRatio(1, contentMode: .fit)
          .overlay {
            JournalMediaImage(relativePath: entry.mediaRelativePath)
              .scaledToFill()
          }
          .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
          .clipShape(RadiusToken.continuousListCard)
          .overlay {
            RadiusToken.continuousListCard
              .strokeBorder(colors.borderSubtle, lineWidth: BorderToken.settingsDivider)
          }
          .overlay(alignment: .topTrailing) {
            JournalDeleteButton(onMedia: true) {
              onDelete(entry.id)
            }
          }
          .accessibilityLabel(entryLabel)
      }
    }
  }
}

struct JournalEntryList: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let entries: [CounterEntry]
  let kind: JournalKind
  var truncates = true
  var onDelete: ((UUID) -> Void)?

  var body: some View {
    if entries.isEmpty {
      EmptyView()
    } else {
      VStack(alignment: .leading, spacing: 0) {
        EntryLogPreviewTableDivider()

        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
          if index > 0 {
            EntryLogRowDivider()
          }
          JournalSavedRow(
            entry: entry,
            kind: kind,
            truncates: truncates,
            onDelete: onDelete.map { delete in
              {
                delete(entry.id)
              }
            }
          )
        }

        Rectangle()
          .fill(colors.textPrimary)
          .frame(height: BorderToken.statsRowStrong)
      }
      .animation(MotionToken.entryInsert(reduceMotion: reduceMotion), value: entries.map(\.id))
    }
  }
}

struct JournalSavedRow: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.designSystem) private var designSystem

  let entry: CounterEntry
  let kind: JournalKind
  var truncates = false
  var onDelete: (() -> Void)?

  @State private var durationLabel = ""

  private var isPlaying: Bool {
    VoicePlayback.shared.playingID == entry.id
  }

  var body: some View {
    switch kind {
    case .photo, .sketch:
      media
    case .voice:
      voice
    case .note:
      noteBlock
    case .book, .movie:
      mediaTitleRow(
        title: catalogTitle,
        subtitle: CatalogNote.subtitle(from: entry.noteText)
      )
    case .place:
      mediaTitleRow(
        title: entry.previewText,
        subtitle: CatalogNote.subtitle(from: entry.noteText)
      )
    case .number:
      textBlock(entry.previewText, wraps: false)
    }
  }

  private var catalogTitle: String {
    let title = CatalogNote.title(from: entry.noteText)
    return title.isEmpty ? kind.entryNoun : title
  }

  private func mediaTitleRow(title: String, subtitle: String) -> some View {
    HStack(alignment: .center, spacing: SpaceToken.u2) {
      JournalMediaImage(relativePath: entry.mediaRelativePath)
        .frame(width: GridToken.units(8), height: GridToken.units(10))
        .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
        .clipShape(RadiusToken.continuousListCard)

      VStack(alignment: .leading, spacing: SpaceToken.u1) {
        Text(title)
          .counterTextStyle(.listCardTitle)
          .lineLimit(truncates ? 2 : nil)
          .frame(maxWidth: .infinity, alignment: .leading)
        if !subtitle.isEmpty {
          Text(subtitle)
            .counterTextStyle(.listCardCaption)
            .lineLimit(1)
        }
        Text(entry.timestamp.formatted(EntryLogRowFormat.timestamp))
          .counterTextStyle(.entryLogTimestamp)
      }

      if let onDelete {
        JournalDeleteButton(action: onDelete)
      }
    }
    .padding(.vertical, SpaceToken.u1)
  }

  private var noteBody: String {
    let trimmed = entry.noteText.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? entry.previewText : trimmed
  }

  private var media: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u1) {
      JournalMediaImage(relativePath: entry.mediaRelativePath)
        .frame(maxWidth: .infinity)
        .frame(height: JournalMediaMetrics.historyHeight)
        .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
        .clipShape(RadiusToken.continuousListCard)
        .overlay(alignment: .topTrailing) {
          if let onDelete {
            JournalDeleteButton(onMedia: true, action: onDelete)
              .padding(SpaceToken.u1)
          }
        }
        .accessibilityLabel(kind.entryNoun)

      Text(entry.timestamp.formatted(EntryLogRowFormat.timestamp))
        .counterTextStyle(.entryLogTimestamp)
    }
    .padding(.vertical, SpaceToken.u2)
  }

  private var voice: some View {
    HStack(alignment: .center, spacing: SpaceToken.u2) {
      Button {
        VoicePlayback.shared.toggle(entryID: entry.id, relativePath: entry.mediaRelativePath)
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
          .foregroundStyle(colors.interactivePrimaryForeground)
          .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
          .background(colors.interactivePrimaryFill, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isPlaying ? "Pause" : "Play")

      VStack(alignment: .leading, spacing: SpaceToken.u1) {
        Text(durationLabel.isEmpty ? kind.entryNoun : durationLabel)
          .counterTextStyle(.listCardTitle)
        Text(entry.timestamp.formatted(EntryLogRowFormat.timestamp))
          .counterTextStyle(.entryLogTimestamp)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let onDelete {
        JournalDeleteButton {
          VoicePlayback.shared.stop()
          onDelete()
        }
      }
    }
    .padding(.vertical, SpaceToken.u1)
    .task(id: entry.mediaRelativePath) {
      durationLabel = await VoiceClipDuration.label(for: entry.mediaRelativePath)
    }
  }

  private var noteBlock: some View {
    let lineLimit: Int? = truncates ? 4 : nil
    let pack = FontPack(rawValue: designSystem.fontPackRaw) ?? .default
    return HStack(alignment: .top, spacing: SpaceToken.u2) {
      VStack(alignment: .leading, spacing: SpaceToken.u1) {
        Text(NoteMarkupDisplay.attributed(noteBody, pack: pack))
          .foregroundStyle(colors.textPrimary)
          .lineLimit(lineLimit)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(entry.timestamp.formatted(EntryLogRowFormat.timestamp))
          .counterTextStyle(.entryLogTimestamp)
      }

      if let onDelete {
        JournalDeleteButton(action: onDelete)
      }
    }
    .padding(.vertical, SpaceToken.u1)
  }

  private func textBlock(_ text: String, wraps: Bool) -> some View {
    let lineLimit: Int? = {
      if !wraps { return 1 }
      return truncates ? 4 : nil
    }()
    return HStack(alignment: .top, spacing: SpaceToken.u2) {
      VStack(alignment: .leading, spacing: SpaceToken.u1) {
        Text(text)
          .counterTextStyle(wraps ? .rowLight : .listCardTitle)
          .lineLimit(lineLimit)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(entry.timestamp.formatted(EntryLogRowFormat.timestamp))
          .counterTextStyle(.entryLogTimestamp)
      }

      if let onDelete {
        JournalDeleteButton(action: onDelete)
      }
    }
    .padding(.vertical, SpaceToken.u1)
  }
}

private enum NoteMarkupDisplay {
  static func attributed(_ source: String, pack: FontPack) -> AttributedString {
    let options = AttributedString.MarkdownParsingOptions(
      interpretedSyntax: .inlineOnlyPreservingWhitespace,
      failurePolicy: .returnPartiallyParsedIfPossible
    )
    var text = (try? AttributedString(markdown: source, options: options)) ?? AttributedString(source)
    let size = TypeStyle.lgRegular.size
    for run in text.runs {
      let intent = run.inlinePresentationIntent ?? []
      let weight: Font.Weight = intent.contains(.stronglyEmphasized) ? .bold : .regular
      var font = pack.font(size: size, weight: weight)
      if intent.contains(.emphasized) {
        font = font.italic()
      }
      text[run.range].font = font
      if intent.contains(.strikethrough) {
        text[run.range].strikethroughStyle = .single
      }
    }
    return text
  }
}

private struct JournalDeleteButton: View {
  @Environment(\.semanticColors) private var colors

  var onMedia = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "xmark")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(onMedia ? colors.interactivePrimaryForeground : colors.textPrimary)
        .frame(width: onMedia ? GridToken.units(4) : SizeToken.iconGlyph, height: onMedia ? GridToken.units(4) : SizeToken.iconGlyph)
        .background {
          if onMedia {
            Circle().fill(colors.interactivePrimaryFill)
          }
        }
        .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Delete entry")
  }
}
