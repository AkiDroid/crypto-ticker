@MainActor
final class AppContainer {
    let appState: AppState
    let priceProvider: any PriceProviding
    let configurationProvider: any AppConfigurationProviding
    let refreshScheduler: any RefreshScheduling

    init(
        appState: AppState,
        priceProvider: any PriceProviding,
        configurationProvider: any AppConfigurationProviding,
        refreshScheduler: any RefreshScheduling
    ) {
        self.appState = appState
        self.priceProvider = priceProvider
        self.configurationProvider = configurationProvider
        self.refreshScheduler = refreshScheduler
    }

    static func bootstrap() -> AppContainer {
        AppContainer(
            appState: AppState(),
            priceProvider: StubPriceProvider(),
            configurationProvider: StubAppConfigurationProvider(),
            refreshScheduler: NoopRefreshScheduler()
        )
    }
}
