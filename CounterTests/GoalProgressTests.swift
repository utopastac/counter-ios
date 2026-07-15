import Testing

struct GoalProgressTests {
  @Test func countUpFractionAndDelta() {
    let progress = GoalProgress(current: 70, goal: 150, direction: .countUp)

    #expect(progress.delta == 80)
    #expect(progress.fractionComplete == 70.0 / 150.0)
    #expect(progress.ringFraction == progress.fractionComplete)
    #expect(!progress.isOverGoal)
    #expect(progress.overflowLoopProgress == 0)
  }

  @Test func countUpOverGoalProducesOverflowProgress() {
    let progress = GoalProgress(current: 180, goal: 150, direction: .countUp)

    #expect(progress.isOverGoal)
    #expect(progress.ringFraction == 1)
    #expect(progress.overflowLoopProgress > 0)
  }

  @Test func overflowLoopProgressStaysUnwrappedPastOneExtraLap() {
    // 350% should read as 2.5 extra laps, not wrap back down to 0.5 — wrapping here is what
    // caused the ring to visibly animate backwards across a lap boundary, since that's the
    // value SwiftUI interpolates between (the ring shape wraps it for drawing instead).
    let progress = GoalProgress(current: 525, goal: 150, direction: .countUp)

    #expect(progress.fractionComplete == 3.5)
    #expect(progress.overflowLoopProgress == 2.5)
  }

  @Test func overflowLoopProgressIsAWholeNumberExactlyOnALapBoundary() {
    let progress = GoalProgress(current: 450, goal: 150, direction: .countUp)

    #expect(progress.fractionComplete == 3)
    #expect(progress.overflowLoopProgress == 2)
  }

  @Test func negativeCurrentIsFlaggedUnderZeroWithNoRingFraction() {
    let progress = GoalProgress(current: -30, goal: 150, direction: .countUp)

    #expect(progress.isUnderZero)
    #expect(progress.ringFraction == 0)
  }

  @Test func negativeCurrentCountDownIsAlsoFlaggedUnderZero() {
    // A negative `current` would otherwise make the countDown formula (delta/goal) read as
    // *more* remaining budget than the goal itself — `isUnderZero` exists so the ring can
    // render empty instead of snapping to a misleadingly full circle.
    let progress = GoalProgress(current: -400, goal: 150, direction: .countDown)

    #expect(progress.isUnderZero)
    #expect(progress.ringFraction == 1)
    #expect(progress.rendersEmptyRing)
  }

  @Test func countUpOverGoalDoesNotRenderEmpty() {
    // Exceeding a count-up target is worth celebrating with the overflow loop, not hiding
    // behind an empty ring.
    let progress = GoalProgress(current: 180, goal: 150, direction: .countUp)

    #expect(!progress.rendersEmptyRing)
  }

  @Test func countDownOverBudgetRendersEmptyRingWithNoOverflowLoop() {
    // Going over a count-down budget isn't an achievement, so — unlike count-up exceeding its
    // target — it should render as a plain empty ring rather than a full ring plus a forward
    // overflow loop.
    let progress = GoalProgress(current: 4500, goal: 3000, direction: .countDown)

    #expect(progress.isOverGoal)
    #expect(progress.rendersEmptyRing)
    #expect(progress.overflowLoopProgress == 0)
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
    #expect(progress.rendersEmptyRing)
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

  // MARK: - compactHeroValue

  @Test func compactHeroValueFoldsGoalContextIntoCountUp() {
    let progress = GoalProgress(current: 70, goal: 150, direction: .countUp)
    #expect(progress.compactHeroValue == "70/150")
  }

  @Test func compactHeroValueMatchesHeroValueForCountDown() {
    let progress = GoalProgress(current: 480, goal: 3000, direction: .countDown)
    #expect(progress.compactHeroValue == progress.heroValue)
  }
}
