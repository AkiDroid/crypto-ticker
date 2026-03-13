import Testing
@testable import CryptoTickerApp

@MainActor
struct TickerCoordinatorTests {
    @Test
    func startTriggersImmediateRefreshAndScheduler() async throws {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: StubLaunchAtLoginManager()
        )

        coordinator.start()
        await Task.yield()
        await Task.yield()

        #expect(scheduler.isRunning)
        #expect(scheduler.lastInterval == 5)
        #expect(appState.statusTitle == "BTC 0.00")
    }

    @Test
    func updateRefreshIntervalRestartsScheduler() async throws {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: StubLaunchAtLoginManager()
        )

        coordinator.start()
        _ = coordinator.updateRefreshInterval(input: "10")

        #expect(scheduler.lastInterval == 10)
        #expect(configurationProvider.refreshInterval == 10)
    }

    @Test
    func selectSymbolPersistsConfiguration() {
        let appState = AppState(customSymbols: ["BNBUSDT"])
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: StubLaunchAtLoginManager()
        )

        coordinator.selectSymbol("BNBUSDT")

        #expect(configurationProvider.selectedSymbol == "BNBUSDT")
    }

    @Test
    func startPersistsNormalizedRefreshIntervalFromLegacyValue() async throws {
        let appState = AppState(refreshInterval: 7)
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: StubLaunchAtLoginManager()
        )

        coordinator.start()
        await Task.yield()
        await Task.yield()

        #expect(appState.refreshInterval == 5)
        #expect(scheduler.lastInterval == 5)
        #expect(configurationProvider.refreshInterval == 5)
    }

    @Test
    func threeConsecutiveRefreshFailuresShowStatusBarErrorIndicator() async throws {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let priceProvider = StubPriceProvider(
            queuedResults: [
                .failure(StubPriceProviderError.notImplemented),
                .failure(StubPriceProviderError.notImplemented),
                .failure(StubPriceProviderError.notImplemented)
            ]
        )
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: priceProvider,
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: StubLaunchAtLoginManager()
        )

        coordinator.start()
        await Task.yield()
        scheduler.fire()
        await Task.yield()
        scheduler.fire()
        await Task.yield()
        scheduler.fire()
        await Task.yield()

        #expect(appState.showsErrorIndicator == true)
    }

    @Test
    func enableLaunchAtLoginUpdatesStateAndPersistsConfiguration() {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let launchAtLoginManager = StubLaunchAtLoginManager()
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: launchAtLoginManager
        )

        coordinator.setLaunchAtLoginEnabled(true)

        #expect(appState.launchAtLoginEnabled == true)
        #expect(configurationProvider.launchAtLoginEnabled == true)
        #expect(appState.detailMessage == AppCopy.launchAtLoginEnabledMessage)
    }

    @Test
    func enableLaunchAtLoginShowsApprovalMessageWhenSystemRequiresApproval() {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let launchAtLoginManager = StubLaunchAtLoginManager(requiresApproval: true)
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: launchAtLoginManager
        )

        coordinator.setLaunchAtLoginEnabled(true)

        #expect(appState.launchAtLoginEnabled == true)
        #expect(appState.detailMessage == AppCopy.launchAtLoginRequiresApprovalMessage)
    }

    @Test
    func launchAtLoginFailureKeepsResolvedStateAndShowsErrorMessage() {
        let appState = AppState(launchAtLoginEnabled: false)
        let scheduler = NoopRefreshScheduler()
        let configurationProvider = StubAppConfigurationProvider()
        let launchAtLoginManager = StubLaunchAtLoginManager(isEnabled: false)
        launchAtLoginManager.shouldThrow = true
        let coordinator = TickerCoordinator(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: configurationProvider,
            refreshScheduler: scheduler,
            launchAtLoginManager: launchAtLoginManager
        )

        coordinator.setLaunchAtLoginEnabled(true)

        #expect(appState.launchAtLoginEnabled == false)
        #expect(appState.detailMessage == AppCopy.launchAtLoginUpdateFailedMessage)
        #expect(configurationProvider.launchAtLoginEnabled == false)
    }
}
