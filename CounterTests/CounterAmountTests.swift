import Testing

struct CounterAmountTests {
  @Test func storageRoundsToHundredths() {
    #expect(CounterAmount.storage(12.5) == 1250)
    #expect(CounterAmount.storage(12.345) == 1235)
  }

  @Test func displayConvertsHundredthsBack() {
    #expect(CounterAmount.display(1250) == 12.5)
    #expect(CounterAmount.display(220_000) == 2200)
  }

  @Test func roundTripPreservesTwoDecimalPlaces() {
    let value = 8.25
    #expect(CounterAmount.display(CounterAmount.storage(value)) == value)
  }
}
