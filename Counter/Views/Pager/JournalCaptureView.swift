import AVFoundation
import CoreLocation
import MapKit
import PhotosUI
import SwiftData
import SwiftUI

/// Writing, recording, and place capture under the ring. Photos and sketches
/// live in `JournalMediaCapture`, where the frames themselves are the control.
struct JournalCaptureFooter: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
  @Environment(\.modelContext) private var modelContext

  @Bindable var counter: CustomCounter
  let onAdded: (EntryActions.AddedEntry) -> Void

  @State private var showWriter = false
  @State private var showPlace = false
  @State private var showCatalog = false

  private var isFull: Bool {
    !counter.acceptsAnotherEntry()
  }

  var body: some View {
    Group {
      if isFull {
        Text(journalFullCaption(counter))
          .counterTextStyle(.listCardCaption)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        capture
      }
    }
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
      PlaceSheet { coordinate in
        let added = EntryActions.addPlaceEntry(
          latitude: coordinate.latitude,
          longitude: coordinate.longitude,
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
      surfaceButton("Write a note") {
        showWriter = true
      } label: {
        Text("Write")
          .counterTextStyle(.rowLight, color: .disabled)
          .frame(maxWidth: .infinity, minHeight: JournalMediaMetrics.writingHeight, alignment: .topLeading)
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
      surfaceButton(counter.kind == .book ? "Search books" : "Search movies") {
        showCatalog = true
      } label: {
        HStack(spacing: SpaceToken.u2) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
            .foregroundStyle(colors.textPrimary)
          Text(counter.kind == .book ? "Search books" : "Search movies")
            .counterTextStyle(.listCardTitle)
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: GridToken.units(8), alignment: .leading)
      }
    case .place:
      surfaceButton("Drop a pin") {
        showPlace = true
      } label: {
        HStack(spacing: SpaceToken.u2) {
          Image(systemName: "mappin")
            .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
            .foregroundStyle(colors.textPrimary)
          Text("Drop a pin")
            .counterTextStyle(.listCardTitle)
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: GridToken.units(8), alignment: .leading)
      }
    case .number, .photo, .sketch:
      EmptyView()
    }
  }

  private func surfaceButton<Label: View>(
    _ accessibilityLabel: String,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
  ) -> some View {
    Button {
      guard !counterRevealIsDragging else { return }
      action()
    } label: {
      label()
        .padding(SpaceToken.u2)
        .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
        .overlay {
          RadiusToken.continuousListCard
            .strokeBorder(colors.borderSubtle, lineWidth: BorderToken.settingsDivider)
        }
    }
    .buttonStyle(.noHighlight)
    .accessibilityLabel(accessibilityLabel)
  }
}

/// The period's photos or sketches, with an empty frame that opens the picker or the drawing sheet.
struct JournalMediaCapture: View {
  @Environment(\.modelContext) private var modelContext

  @Bindable var counter: CustomCounter
  let onAdded: (EntryActions.AddedEntry) -> Void
  let onDelete: (UUID) -> Void

  @State private var selection: PhotosPickerItem?
  @State private var showPicker = false
  @State private var showSketch = false

  private var entries: [CounterEntry] {
    CounterPeriodCalculator.currentEntries(for: counter)
  }

  private var canAdd: Bool {
    counter.acceptsAnotherEntry()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u1) {
      JournalMediaStrip(
        entries: entries,
        showsAdd: canAdd,
        addLabel: counter.kind == .sketch ? "Add a sketch" : "Add a photo",
        entryLabel: counter.kind.entryNoun,
        onAdd: openCapture,
        onDelete: onDelete
      )

      if !canAdd {
        Text(journalFullCaption(counter))
          .counterTextStyle(.listCardCaption)
          .frame(maxWidth: .infinity, alignment: .leading)
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

private func journalFullCaption(_ counter: CustomCounter) -> String {
  "\(counter.resetPeriod.periodCaption.capitalized) is full."
}

private struct NoteWriterSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  @State private var text = ""
  @State private var didKeep = false
  @FocusState private var isFocused: Bool

  let onSave: (String) -> Void

  private var trimmed: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CounterSheetHeader(title: "Note", isDoneEnabled: !trimmed.isEmpty) {
        keep()
        dismiss()
      }

      ZStack(alignment: .topLeading) {
        if text.isEmpty {
          Text("Write")
            .counterTextStyle(.rowLight, color: .disabled)
            .padding(.horizontal, SheetToken.horizontal)
            .padding(.top, SpaceToken.u2)
            .allowsHitTesting(false)
        }

        TextEditor(text: $text)
          .counterTextStyle(.rowLight)
          .scrollContentBackground(.hidden)
          .focused($isFocused)
          .padding(.horizontal, SheetToken.horizontal)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .onAppear { isFocused = true }
    .onDisappear { keep() }
  }

  private func keep() {
    guard !didKeep else { return }
    didKeep = true
    guard !trimmed.isEmpty else { return }
    onSave(trimmed)
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

private struct PlaceSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  @State private var pin: CLLocationCoordinate2D?
  @State private var position: MapCameraPosition = .automatic
  @State private var locator = CurrentLocationReader()

  let onSave: (CLLocationCoordinate2D) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u2) {
      CounterSheetHeader(title: "Place", trailingTitle: "Save", isDoneEnabled: pin != nil) {
        if let pin { onSave(pin) }
        dismiss()
      }

      Text("Tap the map to drop a pin.")
        .counterTextStyle(.listCardCaption)
        .padding(.horizontal, SheetToken.horizontal)

      MapReader { proxy in
        Map(position: $position) {
          if let pin {
            Marker("Place", coordinate: pin)
          }
        }
        .onTapGesture { point in
          pin = proxy.convert(point, from: .local)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .clipShape(RadiusToken.continuousListCard)
      .overlay(alignment: .bottomTrailing) {
        Button {
          locator.request { coordinate in
            pin = coordinate
            position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1200))
          }
        } label: {
          Image(systemName: "location.fill")
            .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
            .foregroundStyle(colors.textPrimary)
            .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
            .background(colors.surfaceSheet, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(SpaceToken.u2)
        .accessibilityLabel("Use current location")
      }
      .padding(.horizontal, SheetToken.horizontal)
      .padding(.bottom, SpaceToken.u2)
    }
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .onAppear {
      locator.request { coordinate in
        guard pin == nil else { return }
        position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1200))
      }
    }
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

private final class CurrentLocationReader: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var onUpdate: ((CLLocationCoordinate2D) -> Void)?

  func request(onUpdate: @escaping (CLLocationCoordinate2D) -> Void) {
    self.onUpdate = onUpdate
    manager.delegate = self
    manager.requestWhenInUseAuthorization()
    manager.requestLocation()
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let coordinate = locations.last?.coordinate else { return }
    Task { @MainActor in
      onUpdate?(coordinate)
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
