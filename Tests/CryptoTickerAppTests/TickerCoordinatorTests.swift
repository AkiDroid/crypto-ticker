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
            refreshScheduler: scheduler
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
            refreshScheduler: scheduler
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
            refreshScheduler: scheduler
        )

        coordinator.selectSymbol("BNBUSDT")

        #expect(configurationProvider.selectedSymbol == "BNBUSDT")
    }
}
