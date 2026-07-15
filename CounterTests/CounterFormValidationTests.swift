import Testing

struct CounterFormValidationTests {
  @Test func allowsEmptyNameWhenNameIsValidated() {
    #expect(CounterFormValidation.canSave(name: "", goalText: ""))
    #expect(CounterFormValidation.canSave(name: "   ", goalText: ""))
    #expect(CounterFormValidation.canSave(name: "Protein", goalText: ""))
  }

  @Test func skipsNameValidationWhenNameIsNil() {
    #expect(CounterFormValidation.canSave(name: nil, goalText: ""))
  }

  @Test func emptyGoalTextIsAlwaysValid() {
    #expect(CounterFormValidation.canSave(name: "Protein", goalText: ""))
    #expect(CounterFormValidation.canSave(name: "Protein", goalText: "   "))
  }

  @Test func nonEmptyGoalTextMustParseToAPositiveInt() {
    #expect(CounterFormValidation.canSave(name: "Protein", goalText: "150"))
    #expect(!CounterFormValidation.canSave(name: "Protein", goalText: "0"))
    #expect(!CounterFormValidation.canSave(name: "Protein", goalText: "-5"))
    #expect(!CounterFormValidation.canSave(name: "Protein", goalText: "abc"))
  }
}
