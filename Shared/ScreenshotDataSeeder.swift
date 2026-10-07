import Foundation
import SwiftData

/// Deterministic counters + history for App Store screenshot capture.
///
/// Replaces whatever is in the store so every `-UITesting` launch looks identical.
enum ScreenshotDataSeeder {
  static let caloriesID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000001")!
  static let proteinID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000002")!
  static let moneyID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000003")!

  /// Days of backdated history (including today).
  private static let historyDayCount = 21

  @MainActor
  static func replaceAll(in context: ModelContext) {
    for counter in (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? [] {
      context.delete(counter)
    }
    AppLog.attempt("Clear store for screenshot seed") { try context.save() }

    let drafts = FreshInstallOnboarding.defaultDrafts().filter {
      [.calories, .protein, .money].contains($0.template)
    }
    SampleDataSeeder.seed(drafts: drafts, in: context)

    let counters = (try? context.fetch(
      FetchDescriptor<CustomCounter>(sortBy: [SortDescriptor(\.sortOrder)])
    )) ?? []

    for counter in counters {
      switch counter.name {
      case "Calories":
        counter.id = caloriesID
        seedCaloriesHistory(for: counter, in: context)
      case "Protein":
        counter.id = proteinID
        seedProteinHistory(for: counter, in: context)
      case "Money":
        counter.id = moneyID
        seedMoneyHistory(for: counter, in: context)
      default:
        break
      }
    }

    AppLog.attempt("Save screenshot seed data") { try context.save() }
  }

  // MARK: - History

  @MainActor
  private static func seedCaloriesHistory(for counter: CustomCounter, in context: ModelContext) {
    // Fixed meal patterns — totals land mid-goal today (~1,280 / 2,000).
    let dayMeals: [[Double]] = [
      [420, 380, 480],       // today
      [350, 520, 610, 180],  // yesterday
      [400, 450, 550],
      [320, 480, 590, 220],
      [440, 390, 510],
      [380, 460, 540, 150],
      [410, 500, 480],
      [360, 420, 580, 200],
      [450, 380, 520],
      [390, 470, 560, 160],
      [430, 410, 490],
      [340, 500, 570, 190],
      [460, 370, 530],
      [400, 440, 510, 170],
      [420, 390, 550],
      [350, 480, 600, 210],
      [440, 400, 500],
      [370, 460, 540, 140],
      [410, 430, 520],
      [380, 490, 560, 180],
      [450, 380, 490],
    ]

    insertDailyMeals(
      dayMeals.prefix(historyDayCount),
      hours: [8, 12, 19, 15],
      for: counter,
      in: context
    )
  }

  @MainActor
  private static func seedProteinHistory(for counter: CustomCounter, in context: ModelContext) {
    let dayMeals: [[Double]] = [
      [30, 40, 35],          // today ~105 / 150
      [25, 45, 40, 20],
      [35, 30, 45],
      [28, 42, 38, 22],
      [32, 40, 36],
      [30, 35, 42, 18],
      [40, 38, 35],
      [26, 44, 40, 24],
      [34, 36, 42],
      [30, 40, 38, 20],
      [32, 38, 40],
      [28, 42, 36, 22],
      [35, 40, 38],
      [30, 35, 40, 25],
      [33, 38, 42],
      [27, 45, 35, 20],
      [36, 34, 40],
      [30, 40, 38, 18],
      [32, 42, 36],
      [28, 38, 40, 22],
      [34, 36, 40],
    ]

    insertDailyMeals(
      dayMeals.prefix(historyDayCount),
      hours: [8, 12, 18, 16],
      for: counter,
      in: context
    )
  }

  @MainActor
  private static func seedMoneyHistory(for counter: CustomCounter, in context: ModelContext) {
    // Sparse spend across ~3 weeks toward a $2,000 monthly budget.
    let spends: [(dayOffset: Int, hour: Int, amount: Double)] = [
      (0, 9, 4.50),
      (0, 13, 12.80),
      (1, 18, 48.00),
      (2, 11, 6.25),
      (3, 20, 32.40),
      (4, 8, 5.75),
      (5, 19, 85.00),
      (6, 12, 14.20),
      (7, 17, 22.50),
      (8, 10, 9.00),
      (9, 21, 56.30),
      (11, 14, 18.75),
      (12, 9, 7.40),
      (13, 19, 110.00),
      (15, 13, 24.60),
      (16, 8, 5.25),
      (18, 20, 41.90),
      (19, 12, 15.00),
      (20, 16, 28.35),
    ]

    let calendar = Calendar.current
    let now = Date.now
    for spend in spends {
      guard let day = calendar.date(byAdding: .day, value: -spend.dayOffset, to: now),
            let timestamp = calendar.date(
              bySettingHour: spend.hour,
              minute: 12,
              second: 0,
              of: day
            )
      else { continue }
      context.insert(CounterEntry(value: spend.amount, timestamp: timestamp, counter: counter))
    }
  }

  @MainActor
  private static func insertDailyMeals(
    _ dayMeals: ArraySlice<[Double]>,
    hours: [Int],
    for counter: CustomCounter,
    in context: ModelContext
  ) {
    let calendar = Calendar.current
    let now = Date.now

    for (dayOffset, meals) in dayMeals.enumerated() {
      guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
      for (mealIndex, amount) in meals.enumerated() {
        let hour = hours[min(mealIndex, hours.count - 1)]
        let minute = 10 + mealIndex * 7
        guard let timestamp = calendar.date(
          bySettingHour: hour,
          minute: minute,
          second: 0,
          of: day
        ) else { continue }
        context.insert(CounterEntry(value: amount, timestamp: timestamp, counter: counter))
      }
    }
  }
}
