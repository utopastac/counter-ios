import Foundation
import HealthKit

@Observable
@MainActor
final class HealthKitManager {
  private let store = HKHealthStore()

  var isAuthorized = false
  var weightKg: Double?
  var activeCalories: Double = 0
  var lastUpdated: Date?

  private var readTypes: Set<HKObjectType> {
    [
      HKQuantityType(.bodyMass),
      HKQuantityType(.activeEnergyBurned)
    ]
  }

  var isHealthDataAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  func requestAuthorization() async {
    guard isHealthDataAvailable else { return }

    do {
      try await store.requestAuthorization(toShare: [], read: readTypes)
      isAuthorized = true
      await refreshToday()
    } catch {
      isAuthorized = false
    }
  }

  func refreshToday() async {
    guard isHealthDataAvailable else { return }

    async let weight = fetchLatestWeight()
    async let active = fetchEnergy(for: .activeEnergyBurned, on: .now)

    weightKg = await weight
    activeCalories = await active
    lastUpdated = .now
  }

  func fetchEnergyHistory(
    for identifier: HKQuantityTypeIdentifier,
    period: HistoryPeriod,
    endingOn date: Date = .now
  ) async -> [DailyValue] {
    let calendar = Calendar.current
    let dayCount = period.dayCount
    guard let startDate = calendar.date(byAdding: .day, value: -(dayCount - 1), to: calendar.startOfDay(for: date)) else {
      return []
    }

    var results: [DailyValue] = []

    for offset in 0..<dayCount {
      guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
      let value = await fetchEnergy(for: identifier, on: day)
      results.append(DailyValue(date: calendar.startOfDay(for: day), value: value))
    }

    return results
  }

  private func fetchLatestWeight() async -> Double? {
    let type = HKQuantityType(.bodyMass)
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: type,
        predicate: nil,
        limit: 1,
        sortDescriptors: [sort]
      ) { _, samples, _ in
        let weight = (samples?.first as? HKQuantitySample)?
          .quantity
          .doubleValue(for: .gramUnit(with: .kilo))
        continuation.resume(returning: weight)
      }
      store.execute(query)
    }
  }

  private func fetchEnergy(for identifier: HKQuantityTypeIdentifier, on date: Date) async -> Double {
    let type = HKQuantityType(identifier)
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: date)
    guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

    return await withCheckedContinuation { continuation in
      let query = HKStatisticsQuery(
        quantityType: type,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
      ) { _, statistics, _ in
        let value = statistics?
          .sumQuantity()?
          .doubleValue(for: .kilocalorie()) ?? 0
        continuation.resume(returning: value)
      }
      store.execute(query)
    }
  }
}
