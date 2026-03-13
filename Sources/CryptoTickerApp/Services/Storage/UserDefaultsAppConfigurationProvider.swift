import Foundation

final class UserDefaultsAppConfigurationProvider: AppConfigurationProviding {
    private enum Key {
        static let selectedSymbol = "app.selectedSymbol"
        static let customSymbols = "app.customSymbols"
        static let refreshInterval = "app.refreshInterval"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadConfiguration() -> AppConfiguration {
        let builtin = AppConfiguration.default.builtinSymbols
        let selected = defaults.string(forKey: Key.selectedSymbol) ?? AppConfiguration.default.selectedSymbol
        let custom = defaults.stringArray(forKey: Key.customSymbols) ?? []
        let refreshInterval = defaults.object(forKey: Key.refreshInterval) as? Double
            ?? AppConfiguration.default.refreshInterval

        return AppConfiguration(
            builtinSymbols: builtin,
            selectedSymbol: selected,
            customSymbols: custom,
            refreshInterval: refreshInterval
        )
    }

    func saveConfiguration(
        selectedSymbol: String,
        customSymbols: [String],
        refreshInterval: TimeInterval
    ) {
        defaults.set(selectedSymbol, forKey: Key.selectedSymbol)
        defaults.set(customSymbols, forKey: Key.customSymbols)
        defaults.set(refreshInterval, forKey: Key.refreshInterval)
    }
}
