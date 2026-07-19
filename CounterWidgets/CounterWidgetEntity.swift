import AppIntents
import Foundation
import SwiftData

struct CounterWidgetEntity: AppEntity, Sendable {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Numo Counter")
  static let defaultQuery = CounterWidgetEntityQuery()

  var id: String
  var title: String
  var paletteIndex: Int
  var sortOrder: Double

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)")
  }
}

struct CounterWidgetEntityQuery: EntityQuery {
  func entities(for identifiers: [CounterWidgetEntity.ID]) async throws -> [CounterWidgetEntity] {
    let all = try await allEntities()
    // Keep a stub for missing IDs so WidgetKit doesn't clear the configuration to nil
    // (nil was previously mapped to the gallery "preview" placeholder).
    return identifiers.map { id in
      all.first { $0.id == id }
        ?? CounterWidgetEntity(
          id: id,
          title: "Counter removed",
          paletteIndex: 0,
          sortOrder: 0
        )
    }
  }

  func suggestedEntities() async throws -> [CounterWidgetEntity] {
    try await allEntities()
  }

  func defaultResult() async -> CounterWidgetEntity? {
    let all = try? await allEntities()
    return all?.first
  }

  @MainActor
  private func allEntities() async throws -> [CounterWidgetEntity] {
    let context = ModelContext(SharedModelContainer.shared)
    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.sortOrder)]
    )
    let counters = try context.fetch(descriptor)

    return counters.map { counter in
      CounterWidgetEntity(
        id: counter.id.uuidString,
        title: counter.name,
        paletteIndex: AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex),
        sortOrder: counter.sortOrder
      )
    }
  }
}
