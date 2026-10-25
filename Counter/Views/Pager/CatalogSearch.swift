import SwiftUI
import UIKit

struct CatalogHit: Identifiable, Equatable {
  let id: String
  let title: String
  let subtitle: String
  let imageURL: URL?
}

enum CatalogNote {
  static func stored(title: String, subtitle: String) -> String {
    let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let subtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !subtitle.isEmpty else { return title }
    return "\(title)\n\(subtitle)"
  }

  static func title(from note: String) -> String {
    note
      .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
      .first
      .map(String.init)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  static func subtitle(from note: String) -> String {
    let parts = note.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count > 1 else { return "" }
    return String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

enum CatalogSearchError: LocalizedError {
  case missingMovieToken
  case failed

  var errorDescription: String? {
    switch self {
    case .missingMovieToken:
      "Movie search needs a TMDB read token in Info.plist."
    case .failed:
      "Search didn’t go through."
    }
  }
}

enum CatalogSearch {
  static func books(matching query: String) async throws -> [CatalogHit] {
    var components = URLComponents(string: "https://openlibrary.org/search.json")
    components?.queryItems = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "limit", value: "8"),
      URLQueryItem(name: "fields", value: "key,title,author_name,first_publish_year,cover_i"),
    ]
    guard let url = components?.url else { throw CatalogSearchError.failed }
    let (data, response) = try await session.data(from: url)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw CatalogSearchError.failed
    }
    let decoded = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
    return decoded.docs.compactMap { doc in
      guard let title = doc.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
        return nil
      }
      let author = doc.author_name?.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let year = doc.first_publish_year.map(String.init) ?? ""
      let subtitle = [author, year].filter { !$0.isEmpty }.joined(separator: " · ")
      let imageURL = doc.cover_i.flatMap { URL(string: "https://covers.openlibrary.org/b/id/\($0)-M.jpg") }
      return CatalogHit(
        id: doc.key ?? "\(title)-\(year)",
        title: title,
        subtitle: subtitle,
        imageURL: imageURL
      )
    }
  }

  static func movies(matching query: String) async throws -> [CatalogHit] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let token = movieToken
    guard !token.isEmpty else { throw CatalogSearchError.missingMovieToken }
    var components = URLComponents(string: "https://api.themoviedb.org/3/search/movie")
    var items = [
      URLQueryItem(name: "query", value: trimmed),
      URLQueryItem(name: "include_adult", value: "false"),
      URLQueryItem(name: "language", value: Locale.current.identifier.replacingOccurrences(of: "_", with: "-")),
    ]
    var requestToken: String?
    if token.contains(".") {
      requestToken = token
    } else {
      items.append(URLQueryItem(name: "api_key", value: token))
    }
    components?.queryItems = items
    guard let url = components?.url else { throw CatalogSearchError.failed }
    var request = URLRequest(url: url)
    if let requestToken {
      request.setValue("Bearer \(requestToken)", forHTTPHeaderField: "Authorization")
    }
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw CatalogSearchError.failed
    }
    let decoded = try JSONDecoder().decode(TMDBResponse.self, from: data)
    return decoded.results.prefix(8).compactMap { movie in
      guard let title = movie.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
        return nil
      }
      let year = movie.release_date.flatMap { String($0.prefix(4)) } ?? ""
      let imageURL = movie.poster_path.flatMap {
        URL(string: "https://image.tmdb.org/t/p/w342\($0)")
      }
      return CatalogHit(id: String(movie.id), title: title, subtitle: year, imageURL: imageURL)
    }
  }

  static func jpegData(from url: URL) async -> Data? {
    guard let (data, response) = try? await session.data(from: url),
          let http = response as? HTTPURLResponse,
          (200..<300).contains(http.statusCode),
          let image = UIImage(data: data)
    else { return nil }
    return image.jpegData(compressionQuality: 0.85) ?? data
  }

  private static var movieToken: String {
    let raw = Bundle.main.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String ?? ""
    return raw.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static let session: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 15
    config.httpAdditionalHeaders = ["User-Agent": "Dayring (com.archgrovehouse.numo)"]
    return URLSession(configuration: config)
  }()
}

struct CatalogSearchSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  let kind: JournalKind
  let onSave: (String, Data?) -> Void

  @State private var query = ""
  @State private var hits: [CatalogHit] = []
  @State private var message = ""
  @State private var savingID: String?
  @State private var searchTask: Task<Void, Never>?
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CounterSheetHeader(
        title: kind == .book ? "Add book" : "Add movie",
        trailingTitle: "Add",
        isDoneEnabled: !typedTitle.isEmpty && savingID == nil
      ) {
        saveTyped()
      }

      TextField(kind == .book ? "Search books" : "Search movies", text: $query)
        .counterTextStyle(.listCardTitle)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .focused($isFocused)
        .padding(SpaceToken.u2)
        .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.bottom, SpaceToken.u2)

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          if !message.isEmpty {
            Text(message)
              .counterTextStyle(.listCardCaption)
              .padding(.horizontal, SheetToken.horizontal)
              .padding(.bottom, SpaceToken.u2)
          }

          ForEach(hits) { hit in
            Button {
              Task { await choose(hit) }
            } label: {
              HStack(alignment: .center, spacing: SpaceToken.u2) {
                CatalogRemoteImage(url: hit.imageURL)
                  .frame(width: GridToken.units(6), height: GridToken.units(8))
                  .background(colors.interactiveSecondaryFill, in: RadiusToken.continuousListCard)
                  .clipShape(RadiusToken.continuousListCard)
                VStack(alignment: .leading, spacing: SpaceToken.u1) {
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
              }
              .padding(.horizontal, SheetToken.horizontal)
              .padding(.vertical, SpaceToken.u1)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(savingID != nil)
          }

        }
      }
    }
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .onAppear { isFocused = true }
    .onChange(of: query) { _, newValue in
      scheduleSearch(newValue)
    }
  }

  private func scheduleSearch(_ raw: String) {
    searchTask?.cancel()
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 2 else {
      hits = []
      message = ""
      return
    }
    searchTask = Task {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      await run(trimmed)
    }
  }

  private func run(_ query: String) async {
    do {
      let found: [CatalogHit]
      if kind == .book {
        found = try await CatalogSearch.books(matching: query)
      } else {
        found = try await CatalogSearch.movies(matching: query)
      }
      guard !Task.isCancelled else { return }
      guard query == self.query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
      hits = found
      message = found.isEmpty ? "Nothing matched." : ""
    } catch let error as CatalogSearchError {
      hits = []
      message = error.localizedDescription
    } catch {
      hits = []
      message = CatalogSearchError.failed.localizedDescription
    }
  }

  private var typedTitle: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func saveTyped() {
    guard !typedTitle.isEmpty, savingID == nil else { return }
    savingID = "manual"
    onSave(CatalogNote.stored(title: typedTitle, subtitle: ""), nil)
    dismiss()
  }

  private func choose(_ hit: CatalogHit) async {
    guard savingID == nil else { return }
    savingID = hit.id
    let note = CatalogNote.stored(title: hit.title, subtitle: hit.subtitle)
    let data: Data?
    if let url = hit.imageURL {
      data = await CatalogSearch.jpegData(from: url)
    } else {
      data = nil
    }
    onSave(note, data)
    dismiss()
  }
}

private struct CatalogRemoteImage: View {
  let url: URL?
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
    .task(id: url) {
      guard let url else {
        image = nil
        return
      }
      guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
      image = UIImage(data: data)
    }
  }
}

private struct OpenLibraryResponse: Decodable {
  struct Doc: Decodable {
    let key: String?
    let title: String?
    let author_name: [String]?
    let first_publish_year: Int?
    let cover_i: Int?
  }

  let docs: [Doc]
}

private struct TMDBResponse: Decodable {
  struct Movie: Decodable {
    let id: Int
    let title: String?
    let release_date: String?
    let poster_path: String?
  }

  let results: [Movie]
}
