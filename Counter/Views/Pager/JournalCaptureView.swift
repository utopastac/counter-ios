import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Writing, recording, and place capture under the ring. Photos and sketches
/// use the same full-width add button from `JournalMediaCapture`.
struct JournalCaptureFooter: View {
  @Environment(\.modelContext) private var modelContext

  @Bindable var counter: CustomCounter
  var buttonHeight: CGFloat = SizeToken.quickAddHeight
  let onAdded: (EntryActions.AddedEntry) -> Void

  @State private var showWriter = false
  @State private var showPlace = false
  @State private var showCatalog = false

  var body: some View {
    capture
    .sheet(isPresented: $showWriter) {
      NoteWriterSheet { text in
        let added = EntryActions.addNoteEntry(text: text, counter: counter, in: modelContext)
        if let added { onAdded(added) }
      }
    }
    .sheet(isPresented: $showCatalog) {
      CatalogSearchSheet(kind: counter.kind) { note, data in
        let added: EntryActions.AddedEntry?
        if let data, !data.isEmpty {
          added = EntryActions.addMediaEntry(
            data: data,
            fileExtension: "jpg",
            counter: counter,
            noteText: note,
            in: modelContext
          )
        } else {
          added = EntryActions.addNoteEntry(text: note, counter: counter, in: modelContext)
        }
        if let added { onAdded(added) }
      }
    }
    .sheet(isPresented: $showPlace) {
      PlaceSheet { coordinate, note, snapshot in
        let added = EntryActions.addPlaceEntry(
          latitude: coordinate.latitude,
          longitude: coordinate.longitude,
          noteText: note,
          snapshot: snapshot,
          counter: counter,
          in: modelContext
        )
        if let added { onAdded(added) }
      }
    }
  }

  @ViewBuilder
  private var capture: some View {
    switch counter.kind {
    case .note:
      CounterActionButton("Add note", height: buttonHeight) {
        showWriter = true
      }
    case .voice:
      VoiceCapture { data in
        let added = EntryActions.addMediaEntry(
          data: data,
          fileExtension: "m4a",
          counter: counter,
          in: modelContext
        )
        if let added { onAdded(added) }
      }
    case .book, .movie:
      CounterActionButton(
        counter.kind == .book ? "Add book" : "Add movie",
        height: buttonHeight
      ) {
        showCatalog = true
      }
    case .place:
      CounterActionButton("Add place", height: buttonHeight) {
        showPlace = true
      }
    case .number, .photo, .sketch:
      EmptyView()
    }
  }
}

/// The period's photos or sketches. The add control is the full-width button; the grid only shows what was saved.
struct JournalMediaCapture: View {
  @Environment(\.modelContext) private var modelContext

  @Bindable var counter: CustomCounter
  var showsEntries = true
  var showsAdd = true
  var entryLimit: Int?
  var buttonHeight: CGFloat = SizeToken.quickAddHeight
  let onAdded: (EntryActions.AddedEntry) -> Void
  let onDelete: (UUID) -> Void

  @State private var selection: PhotosPickerItem?
  @State private var showPicker = false
  @State private var showSketch = false

  private var entries: [CounterEntry] {
    let current = CounterPeriodCalculator.currentEntries(for: counter)
    guard let entryLimit else { return current }
    return Array(current.prefix(entryLimit))
  }

  var body: some View {
    Group {
      if showsEntries {
        JournalMediaStrip(
          entries: entries,
          showsAdd: showsAdd,
          addLabel: counter.kind == .sketch ? "Add a sketch" : "Add a photo",
          entryLabel: counter.kind.entryNoun,
          onAdd: openCapture,
          onDelete: onDelete
        )
      } else {
        CounterActionButton(
          counter.kind == .sketch ? "Add sketch" : "Add photo",
          height: buttonHeight
        ) {
          openCapture()
        }
      }
    }
    .photosPicker(isPresented: $showPicker, selection: $selection, matching: .images)
    .onChange(of: selection) { _, item in
      guard let item else { return }
      Task { await savePhoto(item) }
    }
    .sheet(isPresented: $showSketch) {
      SketchSheet { data in
        let added = EntryActions.addMediaEntry(
          data: data,
          fileExtension: "png",
          counter: counter,
          in: modelContext
        )
        if let added { onAdded(added) }
      }
    }
  }

  private func openCapture() {
    if counter.kind == .sketch {
      showSketch = true
    } else {
      showPicker = true
    }
  }

  private func savePhoto(_ item: PhotosPickerItem) async {
    defer { selection = nil }
    guard let payload = try? await item.loadTransferable(type: JournalPhoto.self) else { return }
    guard let added = EntryActions.addMediaEntry(
      data: payload.data,
      fileExtension: "jpg",
      counter: counter,
      in: modelContext
    ) else { return }
    onAdded(added)
  }
}

private struct NoteWriterSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors
  @Environment(\.designSystem) private var designSystem

  @State private var session = NoteEditorSession()
  @State private var didKeep = false

  let onSave: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CounterSheetHeader(title: "Note", isDoneEnabled: !session.isEmpty) {
        keep()
        dismiss()
      }

      NoteFormatBar(session: session)
        .padding(.horizontal, SheetToken.horizontal)

      ZStack(alignment: .topLeading) {
        if session.isEmpty {
          Text("Write")
            .counterTextStyle(.rowLight, color: .disabled)
            .padding(.horizontal, SheetToken.horizontal)
            .padding(.top, SpaceToken.u2)
            .allowsHitTesting(false)
        }

        NoteTextEditor(session: session)
          .padding(.horizontal, SheetToken.horizontal)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .onAppear {
      let pack = FontPack(rawValue: designSystem.fontPackRaw) ?? .default
      session.configure(font: NoteEditorFont.base(pack: pack), color: UIColor(colors.textPrimary))
      session.textView.becomeFirstResponder()
    }
    .onDisappear { keep() }
  }

  private func keep() {
    guard !didKeep else { return }
    didKeep = true
    let markdown = session.markdown()
    guard !NoteMarkup.plain(markdown).isEmpty else { return }
    onSave(markdown)
  }
}

private struct NoteFormatBar: View {
  @Environment(\.semanticColors) private var colors

  let session: NoteEditorSession

  var body: some View {
    HStack(spacing: SpaceToken.u1) {
      formatButton("bold", label: "Bold", isOn: session.boldOn) { session.toggleBold() }
      formatButton("italic", label: "Italic", isOn: session.italicOn) { session.toggleItalic() }
      formatButton("strikethrough", label: "Strikethrough", isOn: session.strikeOn) { session.toggleStrikethrough() }
      formatButton("list.bullet", label: "List", isOn: session.listOn) { session.toggleList() }
      Spacer(minLength: 0)
    }
    .padding(.bottom, SpaceToken.u1)
  }

  private func formatButton(
    _ systemName: String,
    label: String,
    isOn: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Image(systemName: systemName)
      .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
      .foregroundStyle(isOn ? colors.interactivePrimaryForeground : colors.textPrimary)
      .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
      .background {
        if isOn {
          Circle().fill(colors.interactivePrimaryFill)
        }
      }
      .contentShape(Circle())
      .onTapGesture(perform: action)
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
      .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}

private struct NoteTextEditor: UIViewRepresentable {
  let session: NoteEditorSession

  func makeUIView(context: Context) -> UITextView {
    session.textView
  }

  func updateUIView(_ uiView: UITextView, context: Context) {}
}

private final class NoteEditorDelegate: NSObject, UITextViewDelegate {
  var onChange: () -> Void = {}

  func textViewDidChange(_ textView: UITextView) {
    onChange()
  }

  func textViewDidChangeSelection(_ textView: UITextView) {
    onChange()
  }
}

@MainActor
@Observable
private final class NoteEditorSession {
  let textView = UITextView()
  private let editorDelegate = NoteEditorDelegate()
  private(set) var isEmpty = true
  private(set) var boldOn = false
  private(set) var italicOn = false
  private(set) var strikeOn = false
  private(set) var listOn = false

  private var baseFont = UIFont.preferredFont(forTextStyle: .body)
  private var textColor = UIColor.label

  init() {
    textView.delegate = editorDelegate
    editorDelegate.onChange = { [weak self] in
      self?.refresh()
    }
  }

  func configure(font: UIFont, color: UIColor) {
    baseFont = font
    textColor = color
    textView.backgroundColor = .clear
    textView.font = font
    textView.textColor = color
    textView.tintColor = color
    textView.typingAttributes = typingAttributes(font: font, strike: false)
    textView.textContainerInset = UIEdgeInsets(top: SpaceToken.u2, left: 0, bottom: SpaceToken.u2, right: 0)
    textView.textContainer.lineFragmentPadding = 0
    textView.allowsEditingTextAttributes = true
  }

  func toggleBold() {
    toggleTrait(.traitBold)
  }

  func toggleItalic() {
    toggleTrait(.traitItalic)
  }

  func toggleStrikethrough() {
    let range = textView.selectedRange
    let turningOff = rangeHasStrikethrough(in: textView.attributedText ?? NSAttributedString(), range: range)
    if range.length == 0 {
      var attributes = textView.typingAttributes
      if turningOff {
        attributes.removeValue(forKey: .strikethroughStyle)
      } else {
        attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
      }
      restoreCaret(range)
      textView.typingAttributes = attributes
      refresh()
      return
    }
    editSelection { mutable, range in
      if turningOff {
        mutable.removeAttribute(.strikethroughStyle, range: range)
      } else {
        mutable.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
      }
      textView.attributedText = mutable
    }
  }

  func toggleList() {
    let storage = textView.text as NSString
    let range = textView.selectedRange
    let location = min(range.location, storage.length)
    let lineRange = storage.lineRange(for: NSRange(location: location, length: 0))
    let line = storage.substring(with: lineRange)
    let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
    if line.hasPrefix("- ") {
      mutable.replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "")
      textView.attributedText = mutable
      textView.selectedRange = NSRange(location: max(lineRange.location, range.location - 2), length: 0)
    } else {
      let marker = NSAttributedString(string: "- ", attributes: typingAttributes(font: baseFont, strike: false))
      mutable.insert(marker, at: lineRange.location)
      textView.attributedText = mutable
      textView.selectedRange = NSRange(location: range.location + 2, length: range.length)
    }
    textView.becomeFirstResponder()
    refresh()
  }

  func markdown() -> String {
    let attributed = textView.attributedText ?? NSAttributedString()
    let source = attributed.string as NSString
    var output = ""
    attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attributes, range, _ in
      var chunk = source.substring(with: range)
      let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
      let strike = (attributes[.strikethroughStyle] as? Int ?? 0) != 0
      let token: String? = switch (traits.contains(.traitBold), traits.contains(.traitItalic)) {
      case (true, true): "***"
      case (true, false): "**"
      case (false, true): "*"
      case (false, false): nil
      }
      if let token {
        chunk = marked(chunk, token: token)
      }
      if strike {
        chunk = marked(chunk, token: "~~")
      }
      output += chunk
    }
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
    let range = textView.selectedRange
    if range.length == 0 {
      let current = textView.typingAttributes[.font] as? UIFont
      let strike = (textView.typingAttributes[.strikethroughStyle] as? Int ?? 0) != 0
      let attributes = typingAttributes(font: font(current, toggling: trait), strike: strike)
      restoreCaret(range)
      textView.typingAttributes = attributes
      refresh()
      return
    }
    editSelection { mutable, range in
      mutable.enumerateAttribute(.font, in: range) { value, subrange, _ in
        let updated = font(value as? UIFont, toggling: trait)
        mutable.addAttribute(.font, value: updated, range: subrange)
      }
      textView.attributedText = mutable
    }
  }

  private func marked(_ chunk: String, token: String) -> String {
    chunk.components(separatedBy: "\n").map { part in
      part.isEmpty ? "" : "\(token)\(part)\(token)"
    }.joined(separator: "\n")
  }

  private func restoreCaret(_ range: NSRange) {
    textView.becomeFirstResponder()
    if range.location <= (textView.attributedText?.length ?? 0) {
      textView.selectedRange = range
    }
  }

  private func editSelection(
    _ change: (_ mutable: NSMutableAttributedString, _ range: NSRange) -> Void
  ) {
    let range = textView.selectedRange
    let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
    change(mutable, range)
    textView.becomeFirstResponder()
    if range.location <= textView.attributedText.length {
      textView.selectedRange = range
    }
    refresh()
  }

  private func rangeHasStrikethrough(in text: NSAttributedString, range: NSRange) -> Bool {
    if range.length == 0 {
      return (textView.typingAttributes[.strikethroughStyle] as? Int ?? 0) != 0
    }
    var present = true
    text.enumerateAttribute(.strikethroughStyle, in: range) { value, _, stop in
      if (value as? Int ?? 0) == 0 {
        present = false
        stop.pointee = true
      }
    }
    return present
  }

  private func font(_ current: UIFont?, toggling trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
    let font = current ?? baseFont
    var traits = font.fontDescriptor.symbolicTraits
    if traits.contains(trait) {
      traits.remove(trait)
    } else {
      traits.insert(trait)
    }
    guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return font }
    return UIFont(descriptor: descriptor, size: font.pointSize)
  }

  private func typingAttributes(font: UIFont, strike: Bool) -> [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: textColor,
    ]
    if strike {
      attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }
    return attributes
  }

  private func refresh() {
    isEmpty = NoteMarkup.plain(textView.text).isEmpty
    let attributes = attributesAtSelection()
    let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
    boldOn = traits.contains(.traitBold)
    italicOn = traits.contains(.traitItalic)
    strikeOn = (attributes[.strikethroughStyle] as? Int ?? 0) != 0
    let storage = textView.text as NSString
    let location = min(textView.selectedRange.location, storage.length)
    let line = storage.substring(with: storage.lineRange(for: NSRange(location: location, length: 0)))
    listOn = line.hasPrefix("- ")
  }

  private func attributesAtSelection() -> [NSAttributedString.Key: Any] {
    let range = textView.selectedRange
    let length = textView.attributedText?.length ?? 0
    guard range.length > 0, range.location < length else {
      return textView.typingAttributes
    }
    return textView.attributedText.attributes(at: range.location, effectiveRange: nil)
  }
}

private enum NoteEditorFont {
  static func base(pack: FontPack) -> UIFont {
    let size = TypeStyle.lgRegular.size
    switch pack {
    case .default:
      return .systemFont(ofSize: size, weight: .regular)
    case .soft:
      return designed(.rounded, size: size)
    case .editorial:
      return designed(.serif, size: size)
    case .technical:
      return .monospacedSystemFont(ofSize: size, weight: .regular)
    case .geometric:
      return UIFont(name: FontPack.avenirPostScriptName(for: .regular), size: size)
        ?? .systemFont(ofSize: size, weight: .regular)
    case .nineteenTwentySeven:
      return UIFont(name: FontPack.futuraMediumPostScriptName, size: size)
        ?? .systemFont(ofSize: size, weight: .regular)
    }
  }

  private static func designed(_ design: UIFontDescriptor.SystemDesign, size: CGFloat) -> UIFont {
    let system = UIFont.systemFont(ofSize: size, weight: .regular)
    guard let descriptor = system.fontDescriptor.withDesign(design) else { return system }
    return UIFont(descriptor: descriptor, size: size)
  }
}

private struct VoiceCapture: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging

  @State private var recorder = VoiceNoteRecorder()
  @State private var denied = false
  @State private var didKeep = false

  let onSave: (Data) -> Void

  var body: some View {
    VStack(spacing: SpaceToken.u2) {
      if recorder.isRecording {
        TimelineView(.periodic(from: .now, by: 0.2)) { _ in
          Text(JournalClock.string(from: recorder.elapsed))
            .counterTextStyle(.rowHeavy)
            .monospacedDigit()
        }
        VoiceEqualizer(levels: recorder.levels)
      }

      Button {
        guard !counterRevealIsDragging else { return }
        Task { await toggle() }
      } label: {
        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
          .font(.system(size: SizeToken.tabBarIcon, weight: .semibold))
          .foregroundStyle(colors.interactivePrimaryForeground)
          .frame(width: JournalMediaMetrics.record, height: JournalMediaMetrics.record)
          .background(colors.interactivePrimaryFill, in: Circle())
      }
      .buttonStyle(.noHighlight)
      .accessibilityLabel(recorder.isRecording ? "Stop and save" : "Record")

      if denied {
        Text("Microphone access is off.")
          .counterTextStyle(.listCardCaption)
      }
    }
    .frame(maxWidth: .infinity)
    .onDisappear { keep() }
  }

  private func toggle() async {
    if recorder.isRecording {
      keep()
      return
    }
    let allowed = await AVAudioApplication.requestRecordPermission()
    guard allowed else {
      denied = true
      return
    }
    denied = false
    didKeep = false
    recorder.start()
  }

  private func keep() {
    guard recorder.isRecording, !didKeep else { return }
    didKeep = true
    guard let data = recorder.stop(), !data.isEmpty else { return }
    onSave(data)
  }
}

private struct VoiceEqualizer: View {
  @Environment(\.semanticColors) private var colors

  let levels: [CGFloat]

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x1) {
      ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
        Capsule()
          .fill(colors.interactivePrimaryFill)
          .frame(
            width: SpaceToken.x1,
            height: max(SpaceToken.u1, JournalMediaMetrics.record * level)
          )
      }
    }
    .frame(height: JournalMediaMetrics.record)
    .frame(maxWidth: .infinity)
    .accessibilityHidden(true)
  }
}

private struct JournalPhoto: Transferable {
  let data: Data

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(importedContentType: .image) { data in
      JournalPhoto(data: data)
    }
  }
}

@Observable
private final class VoiceNoteRecorder {
  private var recorder: AVAudioRecorder?
  private var startedAt: Date?
  private var meterTask: Task<Void, Never>?
  private(set) var isRecording = false
  private(set) var levels: [CGFloat] = VoiceNoteRecorder.resting

  private static let barCount = 12
  private static var resting: [CGFloat] {
    Array(repeating: 0.08, count: barCount)
  }

  var elapsed: TimeInterval {
    guard let startedAt, isRecording else { return 0 }
    return Date().timeIntervalSince(startedAt)
  }

  func start() {
    VoicePlayback.shared.stop()
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
    try? session.setActive(true)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44_100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]
    let recorder = try? AVAudioRecorder(url: url, settings: settings)
    recorder?.isMeteringEnabled = true
    recorder?.record()
    self.recorder = recorder
    isRecording = recorder?.isRecording == true
    guard isRecording else { return }
    startedAt = .now
    levels = Self.resting
    meterTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        guard let self, self.isRecording else { return }
        self.sampleLevel()
        try? await Task.sleep(for: .milliseconds(90))
      }
    }
  }

  func stop() -> Data? {
    meterTask?.cancel()
    meterTask = nil
    levels = Self.resting
    let url = recorder?.url
    recorder?.stop()
    recorder = nil
    isRecording = false
    startedAt = nil
    guard let url else { return nil }
    let data = try? Data(contentsOf: url)
    try? FileManager.default.removeItem(at: url)
    return data
  }

  private func sampleLevel() {
    guard let recorder else { return }
    recorder.updateMeters()
    let average = Self.normalized(recorder.averagePower(forChannel: 0))
    let peak = Self.normalized(recorder.peakPower(forChannel: 0))
    var next = levels
    if next.count != Self.barCount {
      next = Self.resting
    }
    for index in next.indices {
      let bias = 0.65 + 0.35 * CGFloat(index) / CGFloat(next.count)
      let source = index.isMultiple(of: 2) ? average : peak
      let target = min(1, max(0.08, source * bias))
      next[index] = next[index] * 0.4 + target * 0.6
    }
    levels = next
  }

  private static func normalized(_ power: Float) -> CGFloat {
    let floor: Float = -48
    let clamped = min(0, max(floor, power))
    return CGFloat((clamped - floor) / -floor)
  }
}
