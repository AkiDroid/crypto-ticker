import Foundation

final class StubAppConfigurationProvider: AppConfigurationProviding {
    private(set) var selectedSymbol: String = AppConfiguration.default.selectedSymbol
    private(set) var customSymbols: [String] = AppConfiguration.default.customSymbols
    private(set) var refreshInterval: TimeInterval = AppConfiguration.default.refreshInterval

    func loadConfiguration() -> AppConfiguration {
        AppConfiguration(
            builtinSymbols: AppConfiguration.default.builtinSymbols,
            selectedSymbol: selectedSymbol,
            customSymbols: customSymbols,
            refreshInterval: refreshInterval
        )
    }

    func saveConfiguration(
        selectedSymbol: String,
        customSymbols: [String],
        refreshInterval: TimeInterval
    ) {
        self.selectedSymbol = selectedSymbol
        self.customSymbols = customSymbols
        self.refreshInterval = refreshInterval
    }
}
