# Testing

## Running tests

```sh
xcodebuild -project Counter.xcodeproj -scheme Counter \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Or in Xcode: select the `Counter` scheme, open the Test navigator (⌘6), and run the
`CounterTests` target (⌘U). `CounterTests` is a hostless unit-test bundle — it doesn't
launch the app, a simulator boot is only needed to satisfy the platform/SDK requirement.

## What's covered

`CounterTests/` covers the pure/near-pure domain logic in `Shared/` — the code that
determines *what the app should compute*, independent of how it's displayed:

| File | Covers |
|---|---|
| `CounterPeriodCalculatorTests.swift` | Daily/weekly/monthly/yearly reset-period range math (including anchor-day edge cases like short months), `resetSummary` strings, period totals, `ordinalDay` formatting |
| `GoalProgressTests.swift` | `GoalProgress` fraction/overflow/percent math for both count-up and count-down goals, `GoalProgressCalculator.progress`/`ringDisplay` |
| `ProgressRingWidthTests.swift` | Thin / balanced / chunky ring stroke ratios and size scaling |
| `HistoryAggregatorTests.swift` | Calendar-day totals and grouped daily/weekly/monthly history buckets |
| `QuickAddConfigurationTests.swift` | Preset normalization (sort + cap), fill-to-count behavior, name-based default preset selection, single-preset replace/append editing |
| `CustomCounterModelTests.swift` | `CustomCounter`'s derived properties: `effectiveGoal`, `effectivePaletteIndex` wraparound, `effectiveResetAnchorDay` clamping, `nextPaletteIndex` cycling |
| `EntryActionsTests.swift` | Stateless CRUD: insert, update, delete a `CounterEntry` |
| `QuickAddSessionStoreTests.swift` | Quick-add batching (accumulate within the 2s window, start fresh after a reset), per-counter and per-instance session isolation, self-healing after the batched entry is deleted directly |
| `AppDataResetTests.swift` | Reset-all restores the three default counters at zero totals without crashing |
| `AmountInputTests.swift` | Numeric text-field sanitization (digits-only, signed, max length) and parsing (positive-int, keypad digit append) |
| `CounterFormValidationTests.swift` | The create/edit form save-gating rule: name requirement, optional-but-must-parse goal text |
| `HistoryChartScaleTests.swift` | History chart Y-axis "nice maximum" selection and tick-value generation |

Tests use an isolated in-memory `ModelContainer` per test
(`CounterTests/TestModelContainer.swift`) — they never touch the real App Group store, so
they can't corrupt device data and don't interfere with each other.

## What's intentionally not covered, and why

- **SwiftUI view rendering** (pager, settings sheet, history chart, list cards). These are
  almost entirely presentation of values already computed by the tested domain logic; the
  highest-value bugs here are visual/layout regressions, which snapshot or UI tests would
  catch better than unit tests — and neither was in scope for this pass. If added later,
  snapshot tests of the `Design/Components/` library would likely have the best
  cost/benefit ratio (small, style-focused, don't need a running app).
- **Widget timeline/entity rendering and App Intents** (`CounterWidgets`, `CounterWatchWidgets`).
  The data these render (`CounterWidgetSnapshot`, ring fractions, hero strings) comes from
  the same tested `Shared/` calculators; the WidgetKit-specific glue
  (`AppIntentTimelineProvider`, `AddCounterEntryIntent`) needs a widget host to exercise
  meaningfully, which is a much heavier test setup for comparatively low logic density.
- **Watch UI** (`CounterWatch` views). Same reasoning as SwiftUI views above — the
  watch-specific logic that *was* worth testing (period vs. calendar-day totals) is now
  exercised indirectly through `CounterPeriodCalculatorTests`, since `WatchCounterListView`
  and `WatchCounterDetailView` both call the same `CustomCounter.currentTotal()` helper.
- **SwiftData persistence/migration at the framework level** (e.g. "does SwiftData survive
  a force-quit mid-write"). Out of scope — this is testing SwiftData itself, not this app's
  logic.

## Adding new tests

If you add a new pure calculation to `Shared/`, add a corresponding `@Test` file in
`CounterTests/`. If it needs a `ModelContext`, use `TestModelContainer.make()` rather than
`SharedModelContainer.shared` — the latter reads/writes the real App Group store.
