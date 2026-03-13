import Foundation

final class StubAppConfigurationProvider: AppConfigurationProviding {
    private(set) var selectedSymbol: String = AppConfiguration.default.selectedSymbol
    private(set) var customSymbols: [String] = AppConfiguration.default.customSymbols
    private(set) var refreshInterval: TimeInterval = AppConfiguration.default.refreshInterval
    private(set) var launchAtLoginEnabled: Bool = AppConfiguration.default.launchAtLoginEnabled

    func loadConfiguration() -> AppConfiguration {
        AppConfiguration(
            builtinSymbols: AppConfiguration.default.builtinSymbols,
            selectedSymbol: selectedSymbol,
            customSymbols: customSymbols,
            refreshInterval: refreshInterval,
            launchAtLoginEnabled: launchAtLoginEnabled
        )
    }

    func saveConfiguration(
        selectedSymbol: String,
        customSymbols: [String],
        refreshInterval: TimeInterval,
        launchAtLoginEnabled: Bool
    ) {
        self.selectedSymbol = selectedSymbol
        self.customSymbols = customSymbols
        self.refreshInterval = refreshInterval
        self.launchAtLoginEnabled = launchAtLoginEnabled
    }
}
