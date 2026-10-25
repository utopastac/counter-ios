import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// Map pin, place search, and the snapshot stored beside the place name.
struct PlaceSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors
  @Environment(\.colorScheme) private var colorScheme

  @State private var pin: CLLocationCoordinate2D?
  @State private var position: MapCameraPosition = .automatic
  @State private var locator = CurrentLocationReader()
  @State private var nearby: CLLocationCoordinate2D?
  @State private var query = ""
  @State private var hits: [PlaceHit] = []
  @State private var message = ""
  @State private var labelNote = ""
  @State private var geocodeToken = 0
  @State private var isSaving = false
  @State private var searchTask: Task<Void, Never>?

  let onSave: (CLLocationCoordinate2D, String, Data?) -> Void

  private var labelTitle: String {
    CatalogNote.title(from: labelNote)
  }

  private var labelSubtitle: String {
    CatalogNote.subtitle(from: labelNote)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.u2) {
      CounterSheetHeader(title: "Place", trailingTitle: "Save", isDoneEnabled: pin != nil && !isSaving) {
        Task { await save() }
      }

      TextField("Search places", text: $query)
        .counterTextStyle(.listCardTitle)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .submitLabel(.search)
        .padding(SpaceToken.u2)
        .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
        .padding(.horizontal, SheetToken.horizontal)

      labelBlock

      if !hits.isEmpty {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(hits) { hit in
              Button {
                choose(hit)
              } label: {
                VStack(alignment: .leading, spacing: SpaceToken.x1) {
                  Text(hit.title)
                    .counterTextStyle(.listCardTitle)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                  if !hit.subtitle.isEmpty {
                    Text(hit.subtitle)
                      .counterTextStyle(.listCardCaption)
                      .lineLimit(1)
                  }
                }
                .padding(.horizontal, SheetToken.horizontal)
                .padding(.vertical, SpaceToken.u1)
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .disabled(isSaving)
            }
          }
        }
        .frame(maxHeight: GridToken.units(24))
      }

      MapReader { proxy in
        Map(position: $position) {
          if let pin {
            Marker(labelTitle.isEmpty ? "Place" : labelTitle, coordinate: pin)
          }
        }
        .onTapGesture { point in
          guard let coordinate = proxy.convert(point, from: .local) else { return }
          drop(coordinate, note: nil)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .clipShape(RadiusToken.continuousListCard)
      .overlay(alignment: .bottomTrailing) {
        Button {
          locator.request { coordinate in
            nearby = coordinate
            drop(coordinate, note: nil)
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
        nearby = coordinate
        guard pin == nil else { return }
        position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1200))
      }
    }
    .onChange(of: query) { _, newValue in
      scheduleSearch(newValue)
    }
  }

  @ViewBuilder
  private var labelBlock: some View {
    if isSaving {
      Text("Saving place…")
        .counterTextStyle(.listCardCaption)
        .padding(.horizontal, SheetToken.horizontal)
    } else if !labelTitle.isEmpty {
      VStack(alignment: .leading, spacing: SpaceToken.x1) {
        Text(labelTitle)
          .counterTextStyle(.listCardTitle)
          .lineLimit(1)
        if !labelSubtitle.isEmpty {
          Text(labelSubtitle)
            .counterTextStyle(.listCardCaption)
            .lineLimit(1)
        }
        if !message.isEmpty {
          Text(message)
            .counterTextStyle(.listCardCaption)
            .lineLimit(2)
        }
      }
      .padding(.horizontal, SheetToken.horizontal)
    } else {
      Text(message.isEmpty ? "Search, or tap the map to drop a pin." : message)
        .counterTextStyle(.listCardCaption)
        .padding(.horizontal, SheetToken.horizontal)
    }
  }

  private func scheduleSearch(_ raw: String) {
    searchTask?.cancel()
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 2 else {
      hits = []
      if labelTitle.isEmpty {
        message = ""
      }
      return
    }
    let near = pin ?? nearby
    searchTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await run(trimmed, near: near)
    }
  }

  private func run(_ query: String, near: CLLocationCoordinate2D?) async {
    do {
      let found = try await PlaceLookup.search(matching: query, near: near)
      guard !Task.isCancelled else { return }
      guard query == self.query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
      hits = found
      message = found.isEmpty ? "Nothing matched." : ""
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      guard query == self.query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
      hits = []
      message = "Search didn’t go through."
    }
  }

  private func choose(_ hit: PlaceHit) {
    CounterKeyboard.resign()
    searchTask?.cancel()
    query = ""
    drop(hit.coordinate, note: hit.note)
  }

  private func drop(_ coordinate: CLLocationCoordinate2D, note: String?) {
    hits = []
    message = ""
    pin = coordinate
    position = .camera(MapCamera(centerCoordinate: coordinate, distance: 1200))
    geocodeToken += 1
    if let note, !note.isEmpty {
      labelNote = note
      return
    }
    labelNote = ""
    let token = geocodeToken
    Task {
      let resolved = await PlaceLookup.note(at: coordinate)
      guard token == geocodeToken else { return }
      labelNote = resolved
    }
  }

  private func save() async {
    guard let pin, !isSaving else { return }
    isSaving = true
    let note = labelNote.isEmpty ? await PlaceLookup.note(at: pin) : labelNote
    let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    let snapshot = await PlaceSnapshot.jpeg(at: pin, interfaceStyle: style)
    onSave(pin, note, snapshot)
    dismiss()
  }
}

private struct PlaceHit: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let coordinate: CLLocationCoordinate2D
  let note: String

  init?(item: MKMapItem) {
    let note = PlaceLookup.note(for: item)
    let title = CatalogNote.title(from: note)
    let coordinate = item.location.coordinate
    guard !title.isEmpty, CLLocationCoordinate2DIsValid(coordinate) else { return nil }
    self.id = "\(title)|\(coordinate.latitude)|\(coordinate.longitude)"
    self.title = title
    self.subtitle = CatalogNote.subtitle(from: note)
    self.coordinate = coordinate
    self.note = note
  }
}

private enum PlaceLookup {
  static func search(matching query: String, near coordinate: CLLocationCoordinate2D?) async throws -> [PlaceHit] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 2 else { return [] }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = trimmed
    request.resultTypes = [.pointOfInterest, .address, .physicalFeature]
    if let coordinate, CLLocationCoordinate2DIsValid(coordinate) {
      request.region = MKCoordinateRegion(
        center: coordinate,
        latitudinalMeters: 40_000,
        longitudinalMeters: 40_000
      )
    }
    let response = try await MKLocalSearch(request: request).start()
    var seen: Set<String> = []
    var hits: [PlaceHit] = []
    for item in response.mapItems {
      guard let hit = PlaceHit(item: item), seen.insert(hit.id).inserted else { continue }
      hits.append(hit)
      if hits.count == 6 { break }
    }
    return hits
  }

  static func note(at coordinate: CLLocationCoordinate2D) async -> String {
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    guard let request = MKReverseGeocodingRequest(location: location) else { return "" }
    guard let item = try? await request.mapItems.first else { return "" }
    return note(for: item)
  }

  static func note(for item: MKMapItem) -> String {
    PlaceLabel.stored(
      name: item.name ?? "",
      street: item.address?.shortAddress ?? "",
      city: item.addressRepresentations?.cityWithContext
        ?? item.addressRepresentations?.cityName
        ?? ""
    )
  }
}

private enum PlaceSnapshot {
  static func jpeg(
    at coordinate: CLLocationCoordinate2D,
    interfaceStyle: UIUserInterfaceStyle
  ) async -> Data? {
    let options = MKMapSnapshotter.Options()
    options.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
    options.region = MKCoordinateRegion(
      center: coordinate,
      latitudinalMeters: 500,
      longitudinalMeters: 500
    )
    options.size = CGSize(width: GridToken.units(8), height: GridToken.units(10))
    options.traitCollection = UITraitCollection(traitsFrom: [
      UITraitCollection(displayScale: 3),
      UITraitCollection(userInterfaceStyle: interfaceStyle),
    ])
    guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return nil }

    let format = UIGraphicsImageRendererFormat()
    format.scale = snapshot.image.scale
    format.opaque = true
    let image = UIGraphicsImageRenderer(size: snapshot.image.size, format: format).image { _ in
      snapshot.image.draw(at: .zero)
      guard let pin = pinImage else { return }
      let point = snapshot.point(for: coordinate)
      pin.draw(at: CGPoint(
        x: point.x - pin.size.width / 2,
        y: point.y - pin.size.height / 2
      ))
    }
    return image.jpegData(compressionQuality: 0.82)
  }

  private static let pinImage: UIImage? = {
    let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
    return UIImage(systemName: "mappin.circle.fill", withConfiguration: configuration)?
      .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
  }()
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
