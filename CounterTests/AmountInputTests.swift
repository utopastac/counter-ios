import Testing

struct AmountInputTests {
  // MARK: - sanitizedDigits

  @Test func sanitizedDigitsStripsNonDigitCharacters() {
    #expect(AmountInput.sanitizedDigits("1a2b3", maxLength: 6) == "123")
    #expect(AmountInput.sanitizedDigits("-5", maxLength: 6) == "5")
  }

  @Test func sanitizedDigitsCapsAtMaxLength() {
    #expect(AmountInput.sanitizedDigits("1234567890", maxLength: 6) == "123456")
  }

  // MARK: - sanitizedSignedDecimal

  @Test func sanitizedSignedDecimalKeepsALeadingMinus() {
    #expect(AmountInput.sanitizedSignedDecimal("-42", maxLength: 7) == "-42")
  }

  @Test func sanitizedSignedDecimalDropsAMinusThatIsNotLeading() {
    #expect(AmountInput.sanitizedSignedDecimal("4-2", maxLength: 7) == "42")
  }

  @Test func sanitizedSignedDecimalCapsAtMaxLength() {
    #expect(AmountInput.sanitizedSignedDecimal("-1234567890", maxLength: 7) == "-123456")
  }

  @Test func sanitizedSignedDecimalAllowsOneDecimalPoint() {
    #expect(AmountInput.sanitizedSignedDecimal("12.34", maxLength: 8) == "12.34")
    #expect(AmountInput.sanitizedSignedDecimal("12.345", maxLength: 8) == "12.34")
  }

  // MARK: - parsePositiveAmount

  @Test func parsePositiveAmountTrimsWhitespace() {
    #expect(AmountInput.parsePositiveAmount("  42  ") == 42)
  }

  @Test func parsePositiveAmountRejectsZeroNegativeAndUnparseableText() {
    #expect(AmountInput.parsePositiveAmount("0") == nil)
    #expect(AmountInput.parsePositiveAmount("-5") == nil)
    #expect(AmountInput.parsePositiveAmount("abc") == nil)
    #expect(AmountInput.parsePositiveAmount("") == nil)
  }

  @Test func parsePositiveAmountAcceptsDecimals() {
    #expect(AmountInput.parsePositiveAmount("12.") == 12)
    #expect(AmountInput.parsePositiveAmount("12.0") == 12)
    #expect(AmountInput.parsePositiveAmount("12.50") == 12.5)
    #expect(AmountInput.parsePositiveAmount("12.4") == 12.4)
    #expect(AmountInput.parsePositiveAmount("0.5") == 0.5)
  }

  // MARK: - parseSignedAmount

  @Test func parseSignedAmountAcceptsZeroAndNegativeValues() {
    #expect(AmountInput.parseSignedAmount("0") == 0)
    #expect(AmountInput.parseSignedAmount("-5") == -5)
    #expect(AmountInput.parseSignedAmount("-12.5") == -12.5)
  }

  // MARK: - appendingDigit

  @Test func appendingDigitAppendsWhenUnderTheLimit() {
    #expect(AmountInput.appendingDigit("3", to: "12", maxDigits: 6) == "123")
  }

  @Test func appendingDigitReplacesALoneLeadingZero() {
    #expect(AmountInput.appendingDigit("5", to: "0", maxDigits: 6) == "5")
  }

  @Test func appendingDigitIsANoOpAtTheLimit() {
    #expect(AmountInput.appendingDigit("7", to: "123456", maxDigits: 6) == "123456")
  }

  @Test func appendingDigitAllowsUpToTwoDecimalPlaces() {
    #expect(AmountInput.appendingDigit("5", to: "12.", maxDigits: 6) == "12.5")
    #expect(AmountInput.appendingDigit("0", to: "12.5", maxDigits: 6) == "12.50")
    #expect(AmountInput.appendingDigit("1", to: "12.50", maxDigits: 6) == "12.50")
  }

  @Test func appendingDigitDoesNotReplaceZeroOnceADecimalIsPresent() {
    #expect(AmountInput.appendingDigit("5", to: "0.", maxDigits: 6) == "0.5")
  }

  // MARK: - appendingDecimalSeparator

  @Test func appendingDecimalSeparatorAddsAPeriod() {
    #expect(AmountInput.appendingDecimalSeparator(to: "12") == "12.")
  }

  @Test func appendingDecimalSeparatorOnEmptyBecomesZeroDot() {
    #expect(AmountInput.appendingDecimalSeparator(to: "") == "0.")
  }

  @Test func appendingDecimalSeparatorIsANoOpWhenAlreadyPresent() {
    #expect(AmountInput.appendingDecimalSeparator(to: "12.") == "12.")
    #expect(AmountInput.appendingDecimalSeparator(to: "12.5") == "12.5")
  }
}
