import Testing

struct CounterAmountTests {
  @Test func roundedKeepsTwoDecimalPlaces() {
    #expect(CounterAmount.rounded(12.5) == 12.5)
    #expect(CounterAmount.rounded(12.345) == 12.35)
    #expect(CounterAmount.rounded(12.344) == 12.34)
  }

  @Test func roundedIsIdempotentForTwoPlaceValues() {
    let value = 12.5
    #expect(CounterAmount.rounded(CounterAmount.rounded(value)) == value)
  }
}
