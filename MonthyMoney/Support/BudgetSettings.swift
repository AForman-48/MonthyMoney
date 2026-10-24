import Foundation

/// Keys and defaults for the settings kept in UserDefaults.
enum BudgetSettings {
    /// Paycheques in a year, used for Annual Income. Monthly income counts as two paycheques.
    static let paychequesKey = "paychequesPerYear"
    static let defaultPaycheques = 26

    static let returnRateKey = "retirementReturnRate"
    static let defaultReturnRate = 0.10

    static let yearsKey = "retirementYears"
    static let defaultYears = 40

    /// Whether the retirement projection is labelled by age rather than year.
    static let usesAgeKey = "retirementUsesAge"
    /// The age in year 1 of the projection.
    static let startAgeKey = "retirementStartAge"
    static let defaultStartAge = 30

    /// Whether budget rows show their pay method.
    static let showsPayMethodsKey = "showsPayMethods"
    static let defaultShowsPayMethods = false

    static let hasCompletedWalkthroughKey = "hasCompletedWalkthrough"
}
