import Foundation

struct AppConfiguration: Equatable {
    let builtinSymbols: [String]
    let selectedSymbol: String
    let customSymbols: [String]
    let refreshInterval: TimeInterval
    let launchAtLoginEnabled: Bool

    static let defaultBuiltinSymbols = ["BTCUSDT", "ETHUSDT", "SOLUSDT"]
    static let defaultRefreshInterval: TimeInterval = 5
    static let refreshIntervalPresets = [3, 5, 10, 30, 60]

    static let `default` = AppConfiguration(
        builtinSymbols: defaultBuiltinSymbols,
        selectedSymbol: defaultBuiltinSymbols[0],
        customSymbols: [],
        refreshInterval: defaultRefreshInterval,
        launchAtLoginEnabled: false
    )
}
