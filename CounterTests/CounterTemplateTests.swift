import Testing

struct CounterTemplateTests {
  @Test func calorieDefaultsMatchSharedCalorieGoalConstant() {
    #expect(CounterTemplate.calories.defaultGoal == CustomCounter.defaultCalorieGoal)
    #expect(CounterTemplate.calories.defaultUnit == "kcal")
    #expect(CounterTemplate.calories.defaultGoalDirection == .countDown)
    #expect(CounterTemplate.calories.defaultResetPeriod == .daily)
  }

  @Test func moneyAndWorkoutsUseNonDailyResetPeriods() {
    #expect(CounterTemplate.money.defaultResetPeriod == .monthly)
    #expect(CounterTemplate.money.defaultGoal == 100)
    #expect(CounterTemplate.workouts.defaultResetPeriod == .weekly)
  }

  @Test func waterUsesCupsUnitConsistentWithCoffee() {
    #expect(CounterTemplate.water.defaultUnit == "cups")
    #expect(CounterTemplate.coffee.defaultUnit == "cups")
  }

  @Test func onboardingDraftDerivesCoreFieldsFromTemplate() {
    for template in CounterTemplate.allCases {
      let draft = FreshInstallStarterDraft.default(for: template)
      #expect(draft.name == template.defaultName)
      #expect(draft.unit == template.defaultUnit)
      #expect(draft.goalDirection == template.defaultGoalDirection)
      #expect(draft.resetPeriod == template.defaultResetPeriod)
      #expect(draft.buttonValues == template.defaultPresets)
      #expect(draft.isSelected == FreshInstallOnboarding.defaultSelectedTemplates.contains(template))

      if let goal = template.defaultGoal {
        #expect(draft.goalText == CounterFormatting.editingText(for: goal))
        #expect(draft.goal == goal)
      } else {
        #expect(draft.goalText.isEmpty)
        #expect(draft.goal == 0)
      }
    }
  }

  @Test func onboardingDefaultSelectionMatchesHistoricStarters() {
    let drafts = FreshInstallOnboarding.defaultDrafts()
    #expect(Set(drafts.filter(\.isSelected).map(\.template)) == [.calories, .protein, .money])
  }

  @Test func draftGoalUsesAmountInputParsing() {
    var draft = FreshInstallStarterDraft.default(for: .calories)
    draft.goalText = "1,800"
    #expect(draft.goal == 1800)

    draft.goalText = "0"
    #expect(draft.goal == 0)

    draft.goalText = "abc"
    #expect(draft.goal == 0)
  }
}
