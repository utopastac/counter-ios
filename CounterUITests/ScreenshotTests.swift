import XCTest

/// App Store screenshot capture. Run via `fastlane screenshots`.
///
/// Each test launches a deterministic `-UITScene` so chrome state is exact
/// (no flaky panel navigation).
final class ScreenshotTests: XCTestCase {
  @MainActor
  func test01Pager() {
    capture(scene: .pager, name: "01-Pager")
  }

  @MainActor
  func test02List() {
    capture(scene: .list, name: "02-List")
  }

  @MainActor
  func test03History() {
    capture(scene: .history, name: "03-History")
  }

  @MainActor
  func test04Compact() {
    capture(scene: .compact, name: "04-Compact")
  }

  @MainActor
  func test05Widgets() {
    capture(scene: .widgets, name: "05-Widgets")
  }

  @MainActor
  private func capture(scene: Scene, name: String) {
    let app = XCUIApplication()
    setupSnapshot(app)
    app.launchArguments += [
      "-UITesting",
      "-UITScene", scene.rawValue,
    ]
    app.launch()

    let ready = app.descendants(matching: .any)["screenshot-ready"]
    XCTAssertTrue(
      ready.waitForExistence(timeout: 15),
      "Timed out waiting for screenshot-ready (\(scene.rawValue))"
    )

    // Brief settle so sheets / reveal animations finish.
    RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    snapshot(name)
  }

  private enum Scene: String {
    case pager = "01-pager"
    case list = "02-list"
    case history = "03-history"
    case compact = "04-compact"
    case widgets = "05-widgets"
  }
}
