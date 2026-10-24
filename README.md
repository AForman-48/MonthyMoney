# MonthyMoney

A SwiftUI app for iPhone and iPad (iOS 26) that replaces the monthly budget spreadsheet. Every amount is monthly. Enter income, essentials, non-essentials and savings, each with the account or card it comes out of, and the app works out the totals, annual figures, the Monthly Spend chart and a retirement projection. Data is stored with SwiftData and synced through iCloud (CloudKit).

## Opening and running

1. Open `MonthyMoney.xcodeproj` in Xcode 26.
2. Select the **MonthyMoney** target, then **Signing & Capabilities**, and pick your team. A paid Apple Developer account is needed for iCloud sync.
3. If Xcode reports that the bundle identifier `ca.aforman.MonthyMoney` or the container `iCloud.ca.aforman.MonthyMoney` is taken, change both to something unique (also update the container name in `MonthyMoneyApp.swift` and `CloudKitSchema.swift`).
4. Run on a simulator or your device. Run the tests with ⌘U.

## Screens

- **Walkthrough**: on first launch, enter your monthly income, one essential (like rent), one non-essential (like a streaming subscription) and one savings item. Savings can be skipped, with a reminder that saving something each month gets the most out of the app.
- **Budget**: the four columns of the sheet as coloured sections (green income, orange essentials, blue non-essentials, purple savings), each with a solid title row showing its monthly total and tinted rows below. Each entry can have a glyph. Tap an entry to edit it, swipe to delete, long-press to duplicate it (or change its pay method), and use Edit to reorder. Take Home stays on a glass bar at the bottom.
- **Summary**: the spreadsheet's first page on one screen: the four colour-headed columns with at least ten rows each and their totals, the monthly and annual blocks stacked on the left, the Monthly Spend pie (touch and hold a slice to see its category and share) and the retirement chart (touch to see each year). Four columns across when there's room, fewer on narrower screens. Tap a row to edit it, or an empty row to add one.
- **Retirement**: the yearly savings invested at a rate of return over a number of years (sliders; 10% and 40 years by default), with a chart you can scrub and an optional starting age so the chart and milestones read by age.
- **Settings**: appearance, pay methods (off by default; turn them on to track the account or card each expense comes out of and to add your own), whether amounts show cents (on by default; when off, amounts are rounded to the nearest dollar for display only), paycheques each year for Annual Income, and a reset.

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

New installs start with an empty budget and no pay methods. If two devices add a pay method with the same name before they sync, the two are merged automatically (`SyncCleanup.swift`). For screenshots, a Debug build launched with `-seedSampleData` fills an empty store with a made-up sample budget, and `-screenshotScreen budget|summary|retirement|settings|walkthrough` opens a screen.
