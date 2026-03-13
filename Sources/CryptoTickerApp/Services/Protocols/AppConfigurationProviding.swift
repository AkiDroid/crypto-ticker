import Foundation

protocol AppConfigurationProviding {
    func loadConfiguration() -> AppConfiguration
    func saveConfiguration(
        selectedSymbol: String,
        customSymbols: [String],
        refreshInterval: TimeInterval,
        launchAtLoginEnabled: Bool
    )
}
