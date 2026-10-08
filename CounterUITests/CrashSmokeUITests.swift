import XCTest

/// Process-survival smoke tests. Launch seeded `-UITesting` scenes, poke the main
/// crash surfaces, and assert the app is still running.
///
/// These are intentionally shallow — they catch SwiftUI first-paint / first-tap
/// crashes, not visual regressions (see `ScreenshotTests`) or domain logic
/// (see `CounterTests`).
final class CrashSmokeUITests: XCTestCase {
  // MARK: - First paint

  @MainActor
  func testPagerSceneLaunchesWithoutCrashing() {
    assertSceneLaunches(.pager)
  }

  @MainActor
  func testListSceneLaunchesWithoutCrashing() {
    assertSceneLaunches(.list)
  }

  @MainActor
  func testHistorySceneLaunchesWithoutCrashing() {
    assertSceneLaunches(.history)
  }

  @MainActor
  func testCompactSceneLaunchesWithoutCrashing() {
    assertSceneLaunches(.compact)
  }

  @MainActor
  func testWidgetsSceneLaunchesWithoutCrashing() {
    assertSceneLaunches(.widgets)
  }

  // MARK: - Interactions

  @MainActor
  func testQuickAddAndUndoDoesNotCrash() {
    let app = launch(scene: .pager)

    let quickAdd = app.buttons["quick-add-100"]
    XCTAssertTrue(quickAdd.waitForExistence(timeout: 5), "Expected quick-add 100 on Calories")
    quickAdd.tap()
    assertAlive(app)

    let undo = app.buttons["Undo"]
    XCTAssertTrue(undo.waitForExistence(timeout: 5), "Expected undo toast after quick-add")
    undo.tap()
    assertAlive(app)
  }

  @MainActor
  func testOpenHistoryAndDismissDoesNotCrash() {
    let app = launch(scene: .pager)

    let history = app.buttons["History"]
    XCTAssertTrue(history.waitForExistence(timeout: 5))
    history.tap()
    assertAlive(app)

    let dismiss = app.buttons["sheet-dismiss"]
    XCTAssertTrue(dismiss.waitForExistence(timeout: 5), "Expected dismiss on history sheet")
    dismiss.tap()
    assertAlive(app)
  }

  @MainActor
  func testOpenCounterSettingsAndDismissDoesNotCrash() {
    let app = launch(scene: .pager)

    let settings = app.buttons["Counter settings"]
    XCTAssertTrue(settings.waitForExistence(timeout: 5))
    settings.tap()
    assertAlive(app)

    let dismiss = app.buttons["sheet-dismiss"]
    XCTAssertTrue(dismiss.waitForExistence(timeout: 5), "Expected dismiss on counter settings")
    dismiss.tap()
    assertAlive(app)
  }

  @MainActor
  func testListSettingsAndAddNewDoNotCrash() {
    let app = launch(scene: .list)

    let settings = app.buttons["tab-settings"]
    XCTAssertTrue(settings.waitForExistence(timeout: 5))
    settings.tap()
    assertAlive(app)

    let settingsDismiss = app.buttons["sheet-dismiss"]
    XCTAssertTrue(settingsDismiss.waitForExistence(timeout: 5))
    settingsDismiss.tap()
    assertAlive(app)

    let addNew = app.buttons["tab-add-new"]
    XCTAssertTrue(addNew.waitForExistence(timeout: 5))
    addNew.tap()
    assertAlive(app)

    let cancel = app.buttons["sheet-dismiss"]
    XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Expected Cancel on create sheet")
    cancel.tap()
    assertAlive(app)
  }

  // MARK: - Helpers

  private enum Scene: String {
    case pager = "01-pager"
    case list = "02-list"
    case history = "03-history"
    case compact = "04-compact"
    case widgets = "05-widgets"
  }

  @MainActor
  private func assertSceneLaunches(_ scene: Scene) {
    let app = launch(scene: scene)
    assertAlive(app)
  }

  @MainActor
  private func launch(scene: Scene) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
      "-UITesting",
      "-UITScene", scene.rawValue,
    ]
    app.launch()

    let ready = app.descendants(matching: .any)["screenshot-ready"]
    XCTAssertTrue(
      ready.waitForExistence(timeout: 15),
      "Timed out waiting for screenshot-ready (\(scene.rawValue))"
    )
    assertAlive(app)
    return app
  }

  @MainActor
  private func assertAlive(_ app: XCUIApplication) {
    // Under XCUITest the app often reports a non-foreground running state (rawValue 3)
    // even when healthy. Only treat notRunning / unknown as a crash signal.
    XCTAssertNotEqual(app.state, .notRunning, "App is not running — likely crashed")
    XCTAssertNotEqual(app.state, .unknown, "App state unknown — likely crashed")
  }
}
