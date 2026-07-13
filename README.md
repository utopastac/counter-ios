# Counter

A simple iOS calorie and custom counter app with Apple Health integration.

## Features

- **Calorie counter** — tap customizable quick-add buttons (10, 20, 50, 100, 200, etc.)
- **Apple Health** — reads weight, active calories burned, and resting (basal) calories
- **Daily balance** — see calories added, burned (active + rest), and net surplus/deficit
- **History** — daily, weekly, and monthly charts for calories added, burned, and net
- **Custom counters** — create named counters (e.g. protein, carbs) that reset daily, with the same button and history features
- **Apple Watch companion** — log calories and counters from your wrist; data syncs with iPhone via a shared App Group
- **Watch complication** — shows today's net calorie balance on your watch face
- **Undo** — reverse the last logged entry on iPhone or Watch

## Requirements

- Xcode 26+ (Swift 6.3)
- iOS 17+ / watchOS 10+
- A physical iPhone and Apple Watch for HealthKit (simulators have limited Health data)

## Setup

1. Open `Counter.xcodeproj` in Xcode
2. Select the **Counter** and **CounterWatch** targets → **Signing & Capabilities**
3. Set your **Team** on **Counter**, **CounterWatch**, and **CounterWatchWidgets** targets
4. Enable **App Groups** (`group.com.becter.counter`) and **HealthKit** on iPhone and Watch targets (entitlements are included)
5. Build and run **Counter** on your iPhone — the Watch app installs automatically when paired

On first launch, grant Health access when prompted so the app can read weight and calorie burn data.

### Apple Watch

The Watch app has two tabs:

- **Calories** — today's burned, added, and net totals, plus quick-add buttons
- **Counters** — browse custom counters created on iPhone and log entries

Entries logged on Watch appear instantly on iPhone (and vice versa) via the shared SwiftData store.

**Complication:** Long-press your watch face → Edit → add the Counter complication. It shows net calories (added − burned).

**Undo:** Tap the ↩ button in the toolbar after logging an entry to remove your last add.

## Project structure

```
Counter/             iOS app
CounterWatch/        watchOS companion
CounterWatchWidgets/ Watch complication (WidgetKit)
Shared/              Models + SwiftData container (App Group)
```

## Notes

- Calorie entries and custom counter totals are stored locally with SwiftData
- Custom counters show **today's total** only on the main screen; full history is in the History sheet
- Pull to refresh or tap the refresh button to update Health data
