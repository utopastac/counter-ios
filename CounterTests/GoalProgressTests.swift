import Testing

struct GoalProgressTests {
  @Test func countUpFractionAndDelta() {
    let progress = GoalProgress(current: 70, goal: 150, direction: .countUp)

    #expect(progress.delta == 80)
    #expect(progress.fractionComplete == 70.0 / 150.0)
    #expect(progress.ringFraction == progress.fractionComplete)
    #expect(!progress.isOverGoal)
    #expect(progress.overflowRingFraction == 0)
  }

  @Test func countUpOverGoalProducesOverflowFraction() {
    let progress = GoalProgress(current: 180, goal: 150, direction: .countUp)

    #expect(progress.isOverGoal)
    #expect(progress.ringFraction == 1)
    #expect(progress.overflowRingFraction > 0)
    #expect(progress.overflowRingFraction <= 1)
  }

  @Test func overflowRingFractionLoopsInsteadOfCappingPastOneExtraLap() {
    // 350% — well past the old "cap at 200%" ceiling — should read as 50% into the
    // *current* lap, not stay pinned at a full extra loop.
    let progress = GoalProgress(current: 525, goal: 150, direction: .countUp)

    #expect(progress.fractionComplete == 3.5)
    #expect(progress.overflowRingFraction == 0.5)
  }

  @Test func overflowRingFractionShowsAFullLoopExactlyOnALapBoundary() {
    // Exactly 300% — a whole number of extra laps — reads as a completed loop (1),
    // matching how the primary ring shows "1" rather than "0" at exactly 100%.
    let progress = GoalProgress(current: 450, goal: 150, direction: .countUp)

    #expect(progress.fractionComplete == 3)
    #expect(progress.overflowRingFraction == 1)
  }

  @Test func negativeCurrentProducesUnderflowFraction() {
    let progress = GoalProgress(current: -30, goal: 150, direction: .countUp)

    #expect(progress.isUnderZero)
    #expect(progress.ringFraction == 0)
    #expect(progress.underflowRingFraction == 0.2)
    #expect(progress.underflowOverlapFraction == 0)
  }

  @Test func underflowRingFractionLoopsPastOneBackwardLap() {
    // -250% — more than one full backward lap — should show a completed backward loop
    // plus 50% into the next one, looping the same way overflow does.
    let progress = GoalProgress(current: -375, goal: 150, direction: .countUp)

    #expect(progress.fractionComplete == -2.5)
    #expect(progress.underflowRingFraction == 1)
    #expect(progress.underflowOverlapFraction == 0.5)
  }

  @Test func countDownRingFractionTracksRemainingBudget() {
    // 480 logged against a 3000 budget leaves 2520 remaining.
    let progress = GoalProgress(current: 480, goal: 3000, direction: .countDown)

    #expect(progress.delta == 2520)
    #expect(progress.ringFraction == 2520.0 / 3000.0)
  }

  @Test func countDownOverBudgetClampsRingToZero() {
    let progress = GoalProgress(current: 3500, goal: 3000, direction: .countDown)

    #expect(progress.delta == -500)
    #expect(progress.isOverGoal)
    #expect(progress.ringFraction == 0)
  }

  @Test func percentCompleteRoundsToNearestInt() {
    let progress = GoalProgress(current: 1, goal: 3, direction: .countUp)
    #expect(progress.percentComplete == 33)
  }

  @Test func calculatorReturnsNilWithoutAPositiveGoal() {
    #expect(GoalProgressCalculator.progress(current: 10, goal: nil, direction: .countUp) == nil)
    #expect(GoalProgressCalculator.progress(current: 10, goal: 0, direction: .countUp) == nil)
    #expect(GoalProgressCalculator.progress(current: 10, goal: -5, direction: .countUp) == nil)
  }

  @Test func calculatorReturnsProgressForAPositiveGoal() {
    let progress = GoalProgressCalculator.progress(current: 10, goal: 20, direction: .countUp)
    #expect(progress?.current == 10)
    #expect(progress?.goal == 20)
  }

  @Test func ringDisplayFallsBackToASafeRingWithoutAGoal() {
    let display = GoalProgressCalculator.ringDisplay(current: 10, goal: nil, direction: .countUp)
    #expect(display.goal == 1)
    #expect(display.current == 0)
    #expect(display.ringFraction == 0)
  }

  @Test func ringDisplayUsesRealGoalWhenPresent() {
    let display = GoalProgressCalculator.ringDisplay(current: 40, goal: 100, direction: .countUp)
    #expect(display.current == 40)
    #expect(display.goal == 100)
  }
}
