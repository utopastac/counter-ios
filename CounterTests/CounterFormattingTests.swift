import Testing

struct CounterFormattingTests {
  @Test func amountOmitsTrailingZerosForWholeNumbers() {
    #expect(CounterFormatting.amount(12) == "12")
    #expect(CounterFormatting.amount(12.0) == "12")
  }

  @Test func amountKeepsUpToTwoDecimalPlaces() {
    #expect(CounterFormatting.amount(12.5) == "12.5")
    #expect(CounterFormatting.amount(12.25) == "12.25")
  }

  @Test func titleWithUnitJoinsWhenPresent() {
    #expect(CounterFormatting.titleWithUnit(name: "Calories", unit: "kcal") == "Calories / kcal")
    #expect(CounterFormatting.titleWithUnit(name: "Protein", unit: "  ") == "Protein")
  }
}
