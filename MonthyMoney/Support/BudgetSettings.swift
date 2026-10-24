import Foundation

/// Keys and defaults for the settings kept in UserDefaults.
enum BudgetSettings {
    /// Months of pay in a year, used for Annual Income. The sheet multiplies by 14.
    static let incomeMonthsKey = "incomeMonthsPerYear"
    static let defaultIncomeMonths = 14.0

    static let returnRateKey = "retirementReturnRate"
    static let defaultReturnRate = 0.10

    static let yearsKey = "retirementYears"
    static let defaultYears = 40
}
