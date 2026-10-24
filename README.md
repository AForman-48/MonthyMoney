# MonthyMoney

A SwiftUI app for iPhone and iPad (iOS 26) that replaces the monthly budget spreadsheet. Every amount is monthly. Enter income, essentials, non-essentials and savings, each with the account or card it comes out of, and the app works out the totals, annual figures, the Monthly Spend chart and a retirement projection. Data is stored with SwiftData and synced through iCloud (CloudKit).

## Opening and running

1. Open `MonthyMoney.xcodeproj` in Xcode 26.
2. Select the **MonthyMoney** target, then **Signing & Capabilities**, and pick your team. A paid Apple Developer account is needed for iCloud sync.
3. If Xcode reports that the bundle identifier `ca.aforman.MonthyMoney` or the container `iCloud.ca.aforman.MonthyMoney` is taken, change both to something unique (also update the container name in `MonthyMoneyApp.swift` and `CloudKitSchema.swift`).
4. Run on a simulator or your device. Run the tests with ⌘U.

## Screens

- **Walkthrough**: on first launch, enter your monthly income, one essential (like rent) and one non-essential (like a streaming subscription).
- **Budget**: the four columns of the sheet as coloured sections (green income, orange essentials, blue non-essentials, purple savings), each with a solid title row showing its monthly total and tinted rows below. Each entry can have a glyph and shows its pay method (hide pay methods in Settings). Tap an entry to edit it, swipe to delete, long-press to change its pay method or duplicate it, and use Edit to reorder. Pay methods and their monthly totals sit at the bottom of the list and behind the card button in the toolbar. Take Home stays on a glass bar at the bottom.
- **Summary**: Total Income, Total Expenses and Take Home; the Monthly Spend donut (tap a slice for its share); the annual figures; the projected retirement savings; and what comes out of each pay method every month.
- **Retirement**: the yearly savings invested at a rate of return over a number of years (sliders; 10% and 40 years by default), with a chart you can scrub, an optional starting age so the chart and milestones read by age, and a look-up for any year or age.
- **Settings**: appearance, showing pay methods on the budget, paycheques each year for Annual Income, and a reset.

## How the figures are worked out

These follow the formulas on the spreadsheet's first sheet:

| Figure | Formula |
| --- | --- |
| Total Expenses | Essentials + Non-Essentials + Savings |
| Take Home | Income − Total Expenses |
| Annual Income | Income × paycheques each year ÷ 2 (monthly income counts as two paycheques; 26 a year is 13 months of pay) |
| Annual Expenses, Take Home, Savings | Monthly figure × 12 |
| Retirement Savings | Each year: (balance + Annual Savings) × (1 + rate), for the number of years |

The sheet's retirement column uses 5% instead of 10% in years 23 and 39, which looks like a typo, so the app uses the same rate every year. With the sheet's numbers that gives $4,849,044 after 40 years rather than the sheet's $4,626,852.

## Sync notes

New installs start with an empty budget and the default pay methods. If two devices add the default pay methods before they sync, pay methods with the same name are merged automatically (`SyncCleanup.swift`). For screenshots, a Debug build launched with `-seedSampleData` fills an empty store with a made-up sample budget, and `-screenshotScreen budget|summary|retirement|settings` opens a screen.
