import Testing
@testable import CryptoTickerApp

@MainActor
struct AppBootstrapperTests {
    @Test
    func bootstrapperAppliesPlaceholderState() {
        let appState = AppState()
        let scheduler = NoopRefreshScheduler()
        let container = AppContainer(
            appState: appState,
            priceProvider: StubPriceProvider(),
            configurationProvider: StubAppConfigurationProvider(),
            refreshScheduler: scheduler
        )

        let bootstrapper = AppBootstrapper(container: container)
        bootstrapper.start()

        #expect(appState.statusTitle == "BTC")
        #expect(appState.detailMessage == AppCopy.defaultDetailMessage)
        #expect(scheduler.isRunning)
    }
}
