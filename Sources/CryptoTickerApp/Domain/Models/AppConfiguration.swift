import Foundation

struct AppConfiguration: Equatable {
    let builtinSymbols: [String]
    let selectedSymbol: String
    let customSymbols: [String]
    let refreshInterval: TimeInterval

    static let defaultBuiltinSymbols = ["BTCUSDT", "ETHUSDT", "SOLUSDT"]
    static let defaultRefreshInterval: TimeInterval = 5

    static let `default` = AppConfiguration(
        builtinSymbols: defaultBuiltinSymbols,
        selectedSymbol: defaultBuiltinSymbols[0],
        customSymbols: [],
        refreshInterval: defaultRefreshInterval
    )
}
