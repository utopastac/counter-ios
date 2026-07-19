# Numo

A simple iOS counter app (calories, custom metrics, and more).

## Features

- **Counters** — tap customizable quick-add buttons (10, 20, 50, 100, 200, etc.)
- **Editable names** — rename any counter, including the default Calories counter
- **History** — daily, weekly, and monthly charts for logged totals
- **Goals** — set targets with count-up or count-down direction
- **Apple Watch companion** — log counters from your wrist; data syncs with iPhone via a shared App Group
- **Watch complication** — shows your default counter total on your watch face
- **Undo** — reverse the last logged entry on iPhone or Watch

## Requirements

- Xcode 26+ (Swift 6.0, strict concurrency)
- iOS 26+ / watchOS 26+

## Setup

1. Open `Counter.xcodeproj` in Xcode
2. Select the **Counter** and **CounterWatch** targets → **Signing & Capabilities**
3. Set your **Team** on **Counter**, **CounterWatch**, and **CounterWatchWidgets** targets
4. Enable **App Groups** (`group.com.becter.counter`) on iPhone and Watch targets (entitlements are included)
5. Build and run the **Counter** scheme (Numo) on your iPhone — the Watch app installs automatically when paired

### Apple Watch

The Watch app lists all counters and lets you log entries from your wrist.

Entries logged on Watch appear instantly on iPhone (and vice versa) via the shared SwiftData store.

**Complication:** Long-press your watch face → Edit → add the Numo complication. It shows your default counter total.

**Undo:** Tap the ↩ button in the toolbar after logging an entry to remove your last add.

## Project structure

```
Counter/             iOS app (Numo)
CounterWatch/        watchOS companion
CounterWidgets/      Home screen widgets (WidgetKit + App Intents)
CounterWatchWidgets/ Watch complication (WidgetKit)
Shared/              Models + SwiftData container (App Group) + domain logic
CounterTests/        Unit tests (Swift Testing) for Shared/ domain logic
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the module map, data flow, and the
reasoning behind the app's architecture, and [docs/DECISIONS.md](docs/DECISIONS.md) for a
log of the specific engineering decisions made while building and refactoring it.

## Testing

Domain logic in `Shared/` is covered by the `CounterTests` target, using Swift Testing.

```sh
xcodebuild -project Counter.xcodeproj -scheme Counter \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Or open the project in Xcode and run the `CounterTests` target from the Test navigator
(⌘U). See [docs/TESTING.md](docs/TESTING.md) for what is and isn't covered, and why.

## Notes

- All counter entries are stored locally with SwiftData
- Counters show the current period total on the main screen; full history is in the History sheet
