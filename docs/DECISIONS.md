# Engineering decisions

A log of the notable decisions made while reviewing, testing, and refactoring this
codebase — what changed, what didn't, and why. See [ARCHITECTURE.md](ARCHITECTURE.md) for
the resulting system design.

## No MVVM / view-model layer

**Decision:** Keep views as the state owner (`@Query`, `@State`, `@Bindable`) and push
domain logic into static enums in `Shared/`, rather than introducing `@Observable` view
models.

**Why:** The app's screens are simple CRUD-over-SwiftData views. `@Query` already gives
reactive, persisted state without any extra plumbing; a view-model layer here would mostly
be forwarding `@Query` results and re-exposing the same static-enum calls views already
make directly. Introducing one now would add ceremony (initializer wiring, environment
injection) without adding testability — the domain logic is already extracted into
plain, model-independent enums that can be (and now are) unit-tested without SwiftUI at
all. If the app grows screens with real cross-cutting, stateful workflows (e.g.
multi-step onboarding, background sync with retry/backoff), that would be the point to
introduce view models — not before.

## Hostless Swift Testing bundle, not XCTest or UI tests

**Decision:** Add `CounterTests` as a `com.apple.product-type.bundle.unit-test` target
using Swift Testing (`import Testing`, `@Test`, `#expect`), with no host app.

**Why:**
- Swift Testing is the modern default for new test code on Swift 6 and reads better for
  the kind of table-style domain tests this app needs (`@Test func ...` per case, `#expect`
  instead of `XCTAssert*`).
- No host app is needed because everything worth unit-testing here (`CounterPeriodCalculator`,
  `GoalProgressCalculator`, `HistoryAggregator`, `EntryActions`, `CalorieMigration`,
  `QuickAddConfiguration`, `CustomCounter`) is plain Swift/SwiftData with no UIKit/SwiftUI
  runtime dependency. A hosted test target would only add launch time and a simulator
  dependency for no benefit.
- Tests build their own in-memory `ModelContainer` (`CounterTests/TestModelContainer.swift`)
  instead of touching `SharedModelContainer`/the App Group, so they're fully isolated from
  device state and from each other.
- UI tests (XCUITest) were intentionally not added — see [TESTING.md](TESTING.md) for what's
  out of scope and why.

## Static enums as the "service layer" instead of DI/protocols

**Decision:** Keep `EntryActions`, `CounterPeriodCalculator`, etc. as static enums rather
than introducing protocols + dependency injection.

**Why:** None of this logic has more than one real implementation, and none of it needs to
be swapped at runtime (there's no "fake network layer" concern — it's local math over
values already fetched from SwiftData, or a `ModelContext` passed in explicitly). Protocols
here would exist solely to satisfy a testing convention, but the functions are already
pure/near-pure and directly testable as-is (proven by `CounterTests`). Introducing
protocol seams without a second implementation would be speculative generality.

## Deleted legacy views instead of keeping them behind a flag

**Decision:** Delete `CustomCountersListView`, `CustomCounterDetailView`, `StatCard`,
`QuickAddButtonsView`, `LargeQuickAddGrid`, `CustomAmountInput`, and `PeriodPicker` rather
than keeping them (e.g. behind a feature flag, or just left in the target).

**Why:** These formed a closed island — reachable only from each other and their own
`#Preview`s, never from `ContentView` → `CounterPagerView` (the app's actual navigation
root), confirmed via a full-repo grep for their initializers. They duplicated logic that
now lives in the active pager UI (settings save/delete handlers, hero/progress display,
quick-add grids) using older, non-design-system styling. Keeping dead code "just in case"
means every future refactor of the *live* logic has to remember to also fix (or
deliberately ignore) the dead copy — which is exactly how `WatchCounterListView`'s total
bug (below) and the palette/ring duplication happened in the first place. If this UI is
needed again, it's a small amount of code to rewrite against the current design system and
current save/delete pipeline, which will be better than reviving a stale copy.

## Palette and progress-ring geometry moved into `Shared/`

**Decision:** Extract `Shared/CounterPaletteData.swift` (raw RGB tuples) and
`Shared/ProgressRingArc.swift` (the ring `Shape`), and have both the app
(`CounterPaletteTokens`, `GoalProgressRing`) and the widget extension (`WidgetPalette`,
`WidgetProgressRing`) build from those shared definitions instead of each maintaining an
independent copy.

**Why:** Both were previously hand-duplicated, byte-for-byte, in two places (confirmed
identical RGB values in `CounterPaletteTokens.swift` and `WidgetPalette.swift`; identical
`Shape` geometry in `GoalProgressView.swift` and `WidgetTheme.swift`). A widget-only fix
(e.g. just editing `WidgetPalette`) would have left the drift risk in place for the next
person who changes a color or tweaks the ring math and only updates one side. `Shared/` was
chosen over a new framework/SPM package because the codebase already uses "compile the same
file into multiple targets" as its sharing mechanism (see [ARCHITECTURE.md](ARCHITECTURE.md)),
so this is consistent with the existing pattern rather than introducing a new one.

## Fixed the watch list/detail total mismatch (data-correctness bug, not style)

**Decision:** Change `WatchCounterListView`'s per-row total from
`HistoryAggregator.counterTotal(..., on: .now)` (calendar day) to
`CounterPeriodCalculator.total`/`counter.currentTotal()` (the counter's actual reset
period), matching `WatchCounterDetailView`.

**Why:** This is not a style preference — it's a bug. For any weekly or monthly counter,
the watch list row showed "today's" total while tapping into the detail view showed the
period total, so the two numbers visibly disagreed for the same counter (regression test:
`CounterPeriodCalculatorTests.periodTotalDiffersFromCalendarDayTotalForAWeeklyCounter`).
Daily counters were unaffected, which is likely why it went unnoticed.

## Consolidated "current total + progress" call sites

**Decision:** Add `CustomCounter.currentTotal()` / `currentProgress()` / `currentRingDisplay()`
(`Shared/CustomCounter+Progress.swift`) and route `AllCountersListView`,
`CustomCounterPageContent`, `WatchCounterDetailView`, `WidgetSnapshotSync`, and
`WidgetCounterLoader` through them instead of each re-deriving
`CounterPeriodCalculator.total(...)` + `GoalProgressCalculator.progress(...)` inline.

**Why:** All five call sites needed the exact same pairing (current period total → goal
progress for that total), but each one spelled it out by hand. That's exactly the shape of
duplication most likely to drift silently — e.g. one call site using the wrong `date`/`calendar`
default, or forgetting `effectiveGoal` vs. `goal`. Centralizing it on `CustomCounter` means
every consumer automatically gets fixes/changes to that pairing (like the watch total fix
above) for free.

## Logging instead of silently swallowed `try?` saves

**Decision:** Add `Shared/Logging.swift` (a small `os.Logger` wrapper, `AppLog.attempt`)
and use it at the `try? context.save()` call sites in `EntryActions`, `CalorieMigration`,
`SampleDataSeeder`, `AppDataReset`, and `WidgetCounterLoader`.

**Why:** These saves were, and still are, treated as best-effort — a full crash-on-save-failure
policy isn't warranted for a local SwiftData store. But `try?` with no logging means a
persistence failure (disk full, migration mismatch, App Group container unavailable) is
completely invisible; you'd only notice because the UI silently didn't update. Wrapping in
`AppLog.attempt` keeps the exact same best-effort behavior while making failures visible in
Console. Deliberately scoped to *save* calls, not every `try? fetch`, since a failed fetch
that legitimately returns "not found" (e.g. `fetchCounterEntry` after a delete) is normal
control flow, not a failure worth logging.

## Settings view split, `ordinalDay` moved to the domain layer

**Decision:** Split the 584-line `ButtonSettingsView.swift` into
`Views/CustomCounters/CounterSettingsView.swift` (the sheet + its state/save logic) and
`Design/Components/SettingsControls.swift` (the reusable row/field/grid components), and
move `ordinalDay(_:)` from a private method on the view into
`CounterResetPeriod.ordinalDay(_:)` in `Shared/CounterPeriod.swift`.

**Why:** The file mixed three concerns — sheet state/validation, one-off row/field/grid
UI components, and a small pure string-formatting helper — at a size that made it hard to
see the actual save/validation logic among ~200 lines of `Settings*` view boilerplate. The
row/field/grid components are generic enough to belong in the design system, not a
feature-specific view file. `ordinalDay` moved because it's domain formatting for
`CounterResetPeriod` (the monthly "resets on the 15th" string), not view state, and moving
it let it be unit-tested directly (`CounterPeriodCalculatorTests.ordinalDayFormatsSuffixesCorrectly`)
instead of only being exercised indirectly through the view.

## What was deliberately left alone

- **`CounterSheetPresentationModifier`'s `DispatchQueue.main.async`** — not converted to
  `Task`/`async`. It defers a UIKit sheet-detent mutation out of `updateUIView`, which needs
  to happen on "the next runloop tick after this UIKit update pass," not "after some
  `Task`-scheduled delay." GCD is the correct tool here, not a legacy pattern to modernize.
- **`CounterWatchWidgets`'s completion-handler `TimelineProvider`** — not switched to
  `AppIntentTimelineProvider` to match the home-screen widget. The complication isn't
  user-configurable and its only data source is a synchronous `UserDefaults` read, so there
  is no asynchronous work that `async`/`await` would meaningfully simplify; switching
  providers would add an App Intent/entity just to match the other target's style, not to
  fix or simplify anything.
- **`CalorieEntry` / `AppSettings` legacy models still in the SwiftData schema** — left in
  place. They exist purely so `CalorieMigration` can find and migrate old data on upgrade;
  removing them from the schema would break migration for anyone upgrading from a version
  before `CustomCounter` existed. This is a "leave until a major version bump that drops
  legacy-upgrade support" decision, not an oversight.
