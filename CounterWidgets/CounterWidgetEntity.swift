import AppIntents
import Foundation
import SwiftData

struct CounterWidgetEntity: AppEntity, Sendable {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Counter")
  static let defaultQuery = CounterWidgetEntityQuery()

  var id: String
  var title: String
  var paletteIndex: Int

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)")
  }
}

struct CounterWidgetEntityQuery: EntityQuery {
  func entities(for identifiers: [CounterWidgetEntity.ID]) async throws -> [CounterWidgetEntity] {
    let all = try await allEntities()
    return identifiers.compactMap { id in
      all.first { $0.id == id }
    }
  }

  func suggestedEntities() async throws -> [CounterWidgetEntity] {
    try await allEntities()
  }

  func defaultResult() async -> CounterWidgetEntity? {
    try? await allEntities().first
  }

  @MainActor
  private func allEntities() async throws -> [CounterWidgetEntity] {
    let context = ModelContext(SharedModelContainer.shared)
    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    let counters = try context.fetch(descriptor)

    return counters.map { counter in
      CounterWidgetEntity(
        id: counter.id.uuidString,
        title: counter.name,
        paletteIndex: counter.effectivePaletteIndex
      )
    }
  }
}
