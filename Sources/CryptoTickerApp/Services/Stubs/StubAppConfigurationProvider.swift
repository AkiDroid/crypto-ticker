final class StubAppConfigurationProvider: AppConfigurationProviding {
    func loadConfiguration() -> AppConfiguration {
        AppConfiguration(
            defaultAsset: CryptoAsset(symbol: "BTC", displayName: "Bitcoin"),
            refreshInterval: 30,
            placeholderStatusMessage: AppCopy.defaultDetailMessage
        )
    }
}
