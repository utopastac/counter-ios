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

  // MARK: - sanitizedSignedDigits

  @Test func sanitizedSignedDigitsKeepsALeadingMinus() {
    #expect(AmountInput.sanitizedSignedDigits("-42", maxLength: 7) == "-42")
  }

  @Test func sanitizedSignedDigitsDropsAMinusThatIsNotLeading() {
    #expect(AmountInput.sanitizedSignedDigits("4-2", maxLength: 7) == "42")
  }

  @Test func sanitizedSignedDigitsCapsAtMaxLength() {
    #expect(AmountInput.sanitizedSignedDigits("-1234567890", maxLength: 7) == "-123456")
  }

  // MARK: - parsePositiveInt

  @Test func parsePositiveIntTrimsWhitespace() {
    #expect(AmountInput.parsePositiveInt("  42  ") == 42)
  }

  @Test func parsePositiveIntRejectsZeroNegativeAndUnparseableText() {
    #expect(AmountInput.parsePositiveInt("0") == nil)
    #expect(AmountInput.parsePositiveInt("-5") == nil)
    #expect(AmountInput.parsePositiveInt("abc") == nil)
    #expect(AmountInput.parsePositiveInt("") == nil)
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
}
