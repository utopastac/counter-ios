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

  @Test func amountWithUnitJoinsWhenPresent() {
    #expect(CounterFormatting.amount(12, unit: "kcal") == "12 kcal")
    #expect(CounterFormatting.amount(12.5, unit: "g") == "12.5 g")
    #expect(CounterFormatting.amount(12, unit: "  ") == "12")
  }

  @Test func editingTextMatchesAmountFormatting() {
    #expect(CounterFormatting.editingText(for: 2200) == "2200")
    #expect(CounterFormatting.editingText(for: 12.5) == "12.5")
  }
}

