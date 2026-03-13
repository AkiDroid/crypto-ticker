@MainActor
final class AppContainer {
    let appState: AppState
    let priceProvider: any PriceProviding
    let configurationProvider: any AppConfigurationProviding
    let refreshScheduler: any RefreshScheduling
    let launchAtLoginManager: any LaunchAtLoginManaging

    init(
        appState: AppState,
        priceProvider: any PriceProviding,
        configurationProvider: any AppConfigurationProviding,
        refreshScheduler: any RefreshScheduling,
        launchAtLoginManager: any LaunchAtLoginManaging
    ) {
        self.appState = appState
        self.priceProvider = priceProvider
        self.configurationProvider = configurationProvider
        self.refreshScheduler = refreshScheduler
        self.launchAtLoginManager = launchAtLoginManager
    }

    static func bootstrap() -> AppContainer {
        let configurationProvider = UserDefaultsAppConfigurationProvider()
        let configuration = configurationProvider.loadConfiguration()
        let launchAtLoginManager = SMAppServiceLaunchAtLoginManager()

        return AppContainer(
            appState: AppState(
                configuration: configuration,
                launchAtLoginEnabled: launchAtLoginManager.isEnabled
            ),
            priceProvider: BinanceFuturesPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: TimerRefreshScheduler(),
            launchAtLoginManager: launchAtLoginManager
        )
    }
}
