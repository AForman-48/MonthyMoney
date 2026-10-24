# MonthyMoney

A SwiftUI app for iPhone and iPad (iOS 26) that replaces the monthly budget spreadsheet. Every amount is monthly. Enter income, essentials, non-essentials and savings, each with the account or card it comes out of, and the app works out the totals, annual figures, the Monthly Spend chart and a retirement projection. Data is stored with SwiftData and synced through iCloud (CloudKit).

## Opening and running

1. Open `MonthyMoney.xcodeproj` in Xcode 26.
2. Select the **MonthyMoney** target, then **Signing & Capabilities**, and pick your team. A paid Apple Developer account is needed for iCloud sync.
3. If Xcode reports that the bundle identifier `ca.aforman.MonthyMoney` or the container `iCloud.ca.aforman.MonthyMoney` is taken, change both to something unique (also update the container name in `MonthyMoneyApp.swift` and `CloudKitSchema.swift`).
4. Run on a simulator or your device. Run the tests with ⌘U.

## Screens

- **Budget**: the four columns of the sheet as sections in their colours (green income, orange essentials, blue non-essentials, purple savings), each with its monthly total. Tap an entry to edit it, swipe to delete, long-press to change its pay method or duplicate it, and use Edit to reorder.
- **Summary**: Total Income, Total Expenses and Take Home; the Monthly Spend donut (tap a slice for its share); the annual figures; the projected retirement savings; and what comes out of each pay method every month.
- **Retirement**: the yearly savings invested at a rate of return over a number of years (10% and 40 years by default, like the sheet), with a chart you can scrub and milestones every five years.
- **Take Home** stays visible above the tab bar on every screen.
- **Settings**: appearance, pay methods (name and colour; the sheet's dropdown list is added on first launch), the months of pay used for Annual Income, and a reset.

## How the figures are worked out

These follow the formulas on the spreadsheet's first sheet:

| Figure | Formula |
| --- | --- |
| Total Expenses | Essentials + Non-Essentials + Savings |
| Take Home | Income − Total Expenses |
| Annual Income | Income × months of pay (14 in the sheet, changeable in Settings) |
| Annual Expenses, Take Home, Savings | Monthly figure × 12 |
| Retirement Savings | Each year: (balance + Annual Savings) × (1 + rate), for the number of years |

The sheet's retirement column uses 5% instead of 10% in years 23 and 39, which looks like a typo, so the app uses the same rate every year. With the sheet's numbers that gives $4,849,044 after 40 years rather than the sheet's $4,626,852.

## Sync notes

New installs start with an empty budget and the default pay methods. If two devices add the default pay methods before they sync, pay methods with the same name are merged automatically (`SyncCleanup.swift`). For screenshots, a Debug build launched with `-seedSampleData` fills an empty store with a made-up sample budget, and `-screenshotScreen budget|summary|retirement|settings` opens a screen.
