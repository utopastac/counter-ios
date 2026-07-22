import Foundation
import SwiftData
import Testing

@MainActor
struct CounterExportTests {
  private func fixedDate() -> Date {
    Date(timeIntervalSince1970: 1_720_000_000) // 2024-07-03T01:46:40Z
  }

  @Test func csvIncludesHeaderAndRowForCounterWithNoEntries() {
    let counter = CustomCounter(
      name: "Water",
      unit: "ml",
      goal: 2000,
      resetPeriod: .daily,
      goalDirection: .countUp,
      sortOrder: 1
    )
    counter.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    let csv = CounterExport.csvString(counters: [counter])
    let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    #expect(lines.first == "counter_id,counter_name,unit,goal,direction,reset_period,entry_id,entry_value,entry_timestamp")
    #expect(lines.contains {
      $0.hasPrefix("AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE,Water,ml,2000,countUp,daily,,,")
    })
    #expect(csv.hasSuffix("\n"))
  }

  @Test func csvEmitsOneRowPerEntrySortedByTimestamp() {
    let counter = CustomCounter(name: "Protein", unit: "g", goal: 150, sortOrder: 1)
    counter.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    let older = CounterEntry(value: 10, timestamp: Date(timeIntervalSince1970: 100), counter: counter)
    older.id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let newer = CounterEntry(value: 20.5, timestamp: Date(timeIntervalSince1970: 200), counter: counter)
    newer.id = UUID(uuidString: "22222222-2222-3333-4444-555555555555")!
    counter.entries = [newer, older]

    let csv = CounterExport.csvString(counters: [counter])
    let dataLines = csv.split(separator: "\n").dropFirst().map(String.init)

    #expect(dataLines.count == 2)
    #expect(dataLines[0].contains("11111111-2222-3333-4444-555555555555,10,"))
    #expect(dataLines[1].contains("22222222-2222-3333-4444-555555555555,20.5,"))
  }

  @Test func csvEscapesCommasQuotesAndNewlinesInNames() {
    let counter = CustomCounter(name: "Coffee, \"dark\"\nroast", unit: "cups", sortOrder: 1)
    counter.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    let csv = CounterExport.csvString(counters: [counter])
    #expect(csv.contains("\"Coffee, \"\"dark\"\"\nroast\""))
  }

  @Test func csvOrdersCountersBySortOrder() {
    let later = CustomCounter(name: "Later", sortOrder: 2)
    later.id = UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let earlier = CustomCounter(name: "Earlier", sortOrder: 1)
    earlier.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    let csv = CounterExport.csvString(counters: [later, earlier])
    let dataLines = csv.split(separator: "\n").dropFirst().map(String.init)

    #expect(dataLines[0].contains("Earlier"))
    #expect(dataLines[1].contains("Later"))
  }

  @Test func csvFilenameUsesNumoPrefixAndCsvSuffix() {
    let name = CounterExport.csvFilename(date: fixedDate())
    #expect(name.hasPrefix("Numo-export-"))
    #expect(name.hasSuffix(".csv"))
    #expect(!name.contains("/"))
    #expect(!name.contains(":"))
  }

  @Test func csvDataMatchesUtf8String() {
    let counter = CustomCounter(name: "Water", sortOrder: 1)
    let string = CounterExport.csvString(counters: [counter])
    #expect(CounterExport.csvData(counters: [counter]) == Data(string.utf8))
  }
}
