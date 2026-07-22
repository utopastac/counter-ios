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
`Shape` geometry in `GoalProgressRing.swift` and `WidgetTheme.swift`). A widget-only fix
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

## `nonisolated` on pure calculators, instead of leaving them under the module's default `@MainActor`

**Decision:** Explicitly mark `CounterPeriodCalculator`, `GoalProgressCalculator`,
`HistoryAggregator`, `QuickAddConfiguration`, `CalorieMigration`, `AppLog`, and the plain
value types they operate on (`CounterResetPeriod`, `CounterPeriodRange`, `GoalDirection`,
`GoalProgress`, `DailyValue`, `HistoryPeriod`) as `nonisolated`, rather than relying on
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` to make them implicitly main-actor-bound.

**Why:** The module-wide default isolation setting is convenient for views and mutators that
already need the main actor (SwiftData's `ModelContext` is main-actor-bound in this app), but
it silently pulls in code that has no actual main-actor dependency — pure functions over
values already in hand. That silent pull-in is exactly what broke
`CounterMigrationPlan.willMigrate`: `CalorieMigration.migrateIfNeeded` needs to run
synchronously from a `@Sendable` closure SwiftData invokes off the main actor, and an
implicitly-`@MainActor` function can't be called from there ("sending 'context' risks causing
data races"). Marking it `nonisolated` fixes that call site and, as a side effect, makes the
type's actual concurrency contract explicit rather than inherited by default. The same
reasoning applies to the other calculators even though nothing currently calls them
off-main-actor: they're pure, so there's no reason to pay a main-actor-hop tax for calling
them from a background context in the future (e.g. a widget doing heavier history
aggregation), and `nonisolated` documents that they're safe to do so.

## `@Model` types don't inherit the module's default actor isolation — documented, not "fixed"

**Decision:** Keep `CustomCounter`/`CounterEntry` themselves unannotated, but explicitly mark
the `CustomCounter+Progress.swift` extension `@MainActor`, with a doc comment explaining why.

**Why:** `@Model` is a macro that expands to its own set of conformances and storage, and that
expansion opts the type out of `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — a `@Model` class
is `nonisolated` by default even in this module, unlike a plain `enum`/`struct`/`class`. This
is a real, non-obvious gotcha: code can compile as `nonisolated` against a `@Model` type's
*type declarations* while still being wrong to call from off the main actor, because the
*store* backing that model (via `ModelContext`) is main-actor-bound in this app even though
the Swift type isn't. `CustomCounter+Progress.swift`'s accessors read `self.entries` (a
relationship), so they need `@MainActor` explicitly — there's no way to make the compiler
enforce this automatically without also making `CustomCounter` itself `@MainActor` (which
would then make routine SwiftData/`@Query` usage require await-hops it doesn't need). The fix
here is documentation, not a code change to `CustomCounter` itself.

## Quick-add batching moved out of a hidden `private static var` into `QuickAddSessionStore`

**Decision:** Extract the quick-add batching window (which entry a rapid second tap should
accumulate into, and when the window expires) out of `EntryActions` and into a new
`QuickAddSessionStore` class that call sites own explicitly (`@State` in
`CustomCounterPageContent`/`WatchCounterDetailView`, `.shared` in the widget extension).
`EntryActions` is now purely stateless CRUD.

**Why:** The original design kept `quickAddSessions: [UUID: Session]` as a `private static
var` inside `EntryActions`, which otherwise reads as a stateless enum of pure CRUD functions.
That's a hidden global: nothing in `EntryActions`'s public surface suggests it's holding
mutable state with a lifetime, and every call site was implicitly sharing one global batching
window regardless of which screen was on-screen or which counter's page had been dismissed
and re-opened. Giving it a real, referenceable type makes the lifetime explicit and lets each
owner scope it correctly — a counter page's batching window dying when the page does (via
`@State`) is the right behavior, and the widget extension's `.shared` singleton is now a
deliberate, visible choice rather than an implicit side effect of `EntryActions` being an
enum. It's also more testable in isolation: `QuickAddSessionStoreTests` can construct
independent store instances to prove sessions don't leak across them, which wasn't possible
to express cleanly when the state was `private` inside `EntryActions`.

## SwiftData `VersionedSchema`/`SchemaMigrationPlan` instead of an imperative migration call

> **Superseded.** Pre-release cleanup removed `VersionedSchema`, `CalorieMigration`, and
> legacy `CalorieEntry`/`AppSettings`. The live schema is a plain
> `Schema([CustomCounter, CounterEntry])`; breaking changes bump `AppGroup.storeFilename`.
> Left below for historical context.

**Decision:** Replace the imperative `CalorieMigration.migrateIfNeeded(in:)` call (previously
made by hand from `SampleDataSeeder.seedIfNeeded` on every launch) with a declarative
`CounterSchemaV1` → `CounterSchemaV2` `SchemaMigrationPlan`
(`Shared/CounterSchemaMigrationPlan.swift`), wired into `SharedModelContainer` via
`ModelContainer(for:migrationPlan:configurations:)`.

**Why:** The old design re-derived "should I check for legacy data?" on every single app
launch via a guard clause at the top of `migrateIfNeeded` — cheap, but conceptually wrong: an
old-schema-to-new-schema data move is exactly the problem `SchemaMigrationPlan` exists to
solve, and SwiftData already knows how to run a migration stage exactly once, at store-open
time, only when the store is actually shaped like the old schema. Modeling it that way also
makes the migration end-to-end testable in a way the imperative version wasn't:
`SchemaMigrationPlanTests` opens a real file-backed store shaped like `CounterSchemaV1`,
closes it, and reopens the same file against `CounterSchemaV2` with the plan attached — the
same path a real app upgrade takes — rather than only testing `CalorieMigration`'s data-moving
logic in isolation (which `CalorieMigrationTests` still does, and continues to be useful for).
`CalorieEntry`/`AppSettings` stay in `CounterSchemaV1` and drop out of `CounterSchemaV2`,
formalizing what was previously an implicit "these are legacy, don't add new features to them"
convention into the schema itself.

## `@Entry` macro instead of hand-written `EnvironmentKey` boilerplate

**Decision:** Replace `DesignSystemEnvironment.swift`'s six hand-written
`private struct FooKey: EnvironmentKey { static let defaultValue = ... }` +
`extension EnvironmentValues { var foo: T { get { self[FooKey.self] } set { ... } } }` pairs
with `@Entry` (SwiftUI's macro for exactly this, available since iOS 17).

**Why:** Every one of those keys existed solely to give `EnvironmentValues` a new property;
none had custom subscript behavior worth the boilerplate. `@Entry` generates the same
`EnvironmentKey` + subscript accessor pair from a single `@Entry var foo: T = default`
declaration. The one property with genuine custom logic — `designSystem`, which layers
`counterAccent` on top of a stored value on read — keeps a hand-written computed property,
but now wraps a `@Entry`-backed `fileprivate` raw value instead of a hand-written key, so only
the actually-custom part remains hand-written.

## Embedded view logic extracted into `Shared/`, once it was actually duplicated or diverging

**Decision:** After deciding against an MVVM/view-model layer (see above), do a second pass
over the view files specifically looking for logic that had drifted from "view-specific
presentation" into "domain rule reimplemented per-view" — as opposed to extracting everything
that merely *touches* a view's `@State`. Pulled out: numeric text-field sanitization/parsing
(`Shared/AmountInput.swift`), the create/edit form save-gating rule
(`Shared/CounterFormValidation.swift`), reset-period anchor-day defaulting/normalization
(added to `Shared/CounterPeriod.swift`), the history chart's axis-scaling math
(`Shared/HistoryChartScale.swift`), "this counter's current-period entries, newest first"
(added to `Shared/CounterPeriod.swift`), which built-in preset set a counter defaults to by
name and the settings preset-field edit rule (added to `Shared/QuickAddConfiguration.swift`),
a compact Watch-only hero-value format (added to `Shared/GoalDirection.swift`), and a named
"next palette slot" helper (added to `CustomCounter`).

**Why:** Grepping the view layer for `Int(...)`, `.filter(\.isWholeNumber)`, and hand-rolled
`switch`/`if` chains over `CounterResetPeriod`/`GoalDirection` turned up several cases where
the *same* rule had been typed out at 2–3 call sites with small, accidental differences rather
than one deliberate difference:
- `AmountEntrySheet`, `SettingsEditablePresetField`, and `EntryLogEditableRow` each sanitized
  typed digits slightly differently (different max lengths, only one of them allowing a
  leading `-`) with no comment explaining why they differed — they were supposed to agree
  except where entry-log editing legitimately needs signed values.
- `CreateCounterView` always overwrote the reset-anchor day on period change, while
  `CounterSettingsView` only corrected it when it became invalid for the new period. These
  were the *same intended rule*, not two deliberate designs — unifying on the settings view's
  behavior (which is strictly more correct: it doesn't discard a still-valid anchor) fixed a
  latent bug in the create flow, where toggling between periods could silently reset a
  weekday/day-of-month the user had already picked.
- Only `CounterSettingsView`'s default-preset selection special-cased a counter named
  "Calories"; `CustomCounterPageContent`'s quick-add grid, `WidgetCounterLoader`'s widget
  snapshot, and `WatchCounterDetailView`'s grid all silently fell back to the generic preset
  set for the same counter. This was an actual behavioral bug (a Calories counter showed
  different quick-add numbers depending on which surface you were looking at it from), not
  just style debt.
- The Watch quick-add grid used `normalizedPresets` (show only what's stored) while the
  iPhone's used `filledPresets` (pad out to a full grid); after switching the Watch grid to
  `filledPresets` too, both surfaces show the same number of buttons for the same counter.
- The Watch hero-value format (`"70/150"` for a count-up goal, vs. every other surface's plain
  `"70"`) turned out to be a deliberate compensation for the Watch view having no second
  caption line, not an oversight — so instead of force-unifying it, it became a named,
  documented, tested `GoalProgress.compactHeroValue` property, making the difference visible
  and intentional instead of inline `switch` logic buried in `WatchCounterDetailView`.

What this pass explicitly avoided doing: it did not wrap trivial one-line reads
(`counter.effectiveGoal`, simple string formatting with no branching) or view-only concerns
(sheet presentation state, animation timing) in a "Shared" abstraction just to hit an
extraction quota. The bar was "is this the same rule appearing more than once, and could a new
call site plausibly get it subtly wrong" — the same bar `EntryActions`/`QuickAddSessionStore`
were held to earlier in this log.

## `FPSMonitor` uses Observation, not `ObservableObject`

**Decision:** Convert the debug FPS HUD's `FPSMonitor` from `ObservableObject` /
`@Published` / `@StateObject` to `@Observable` / `@State`.

**Why:** It was the last Combine-era observation type in the app. Everything else that
needs a reference-type observation surface (`RevealState`, sheet helpers) already uses the
Observation framework. Aligning the HUD removes the odd one out without changing behavior;
`CADisplayLink` stays — there is no SwiftUI equivalent for frame sampling.

## iPhone haptics via `.sensoryFeedback`; Watch keeps `AppHaptics`

**Decision:** Drive iPhone impact/undo feedback with SwiftUI `.sensoryFeedback` triggers
gated by `@AppStorage(AppAppearancePreference.hapticsEnabledKey)`. Leave
`Shared/AppHaptics.swift` as the Watch path (`WKInterfaceDevice`).

**Why:** `.sensoryFeedback` is the platform idiom for view-tied haptics on iOS and
composes with SwiftUI state. Watch has no equivalent modifier surface for the same call
sites, so the shared imperative helper remains there. The user preference still gates both
paths.

## UIKit owns pager/reveal gesture arbitration

**Decision:** Drive horizontal list-reveal with a UIKit `UIPanGestureRecognizer`
(`RevealPanBridge`) and full-mode vertical paging with a UIKit `UIScrollView`
(`VerticalPagerScrollView`). Keep SwiftUI for page content and the underlay list.
Do **not** toggle SwiftUI `.scrollDisabled` or call `setContentOffset` to “fix”
interrupted pans.

**Why:** The previous SwiftUI-only stack (`DragGesture` + `simultaneousGesture` +
paging `ScrollView` + `scrollPosition`) was structurally brittle on iOS 26, where
`simultaneousGesture` no longer propagates to ancestor scroll pans (RN 147970990).
Side-channel bridges (`ScrollPanDisabler`, bounce re-assert, gated `scrollPosition`)
kept regressing as last-page jumps. UIKit can disable competing scroll pans on a
horizontal claim and own bounce/paging as real properties. Compact mode still uses
a SwiftUI `ScrollView` with `ScrollPanDisabler`; `ScrollPanGate` covers both when
reveal claims the gesture.

## What was deliberately left alone

- **`RingTipHalo.lapFraction` (`Counter/Views/Components/GoalProgressRing.swift`) duplicates
  `ProgressRingArc.lapFraction`** rather than sharing it. Both are tiny (4-line), private,
  file-local helpers on otherwise-unrelated `Shape`s; the type's own doc comment explains why
  a cross-file dependency isn't worth it for something this small and self-contained. Revisited
  during the `Shared/` extraction pass above and left as-is — this is a case where the
  duplication is genuinely cheaper than the abstraction.
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
- **Liquid Glass chrome / `CounterToggle` → system `Toggle`** — deferred; branded solid
  surfaces and the custom toggle stay as-is for this pass.
