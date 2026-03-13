import Testing
@testable import CryptoTickerApp

@MainActor
struct AppBootstrapperTests {
    private final class CoordinatorSpy: TickerCoordinating {
        private(set) var startCallCount = 0
        private(set) var stopCallCount = 0

        func start() {
            startCallCount += 1
        }

        func stop() {
            stopCallCount += 1
        }

        func selectSymbol(_ symbol: String) {}

        func addCustomSymbol(input: String) -> AppState.SymbolMutationResult {
            .invalidInput
        }

        func removeCustomSymbol(_ symbol: String) -> Bool {
            false
        }

        func updateRefreshInterval(input: String) -> AppState.IntervalMutationResult {
            .invalidFormat
        }

        func setLaunchAtLoginEnabled(_ enabled: Bool) {}
    }

    @Test
    func bootstrapperDelegatesLifecycleToCoordinator() {
        let coordinator = CoordinatorSpy()
        let bootstrapper = AppBootstrapper(coordinator: coordinator)

        bootstrapper.start()
        bootstrapper.stop()

        #expect(coordinator.startCallCount == 1)
        #expect(coordinator.stopCallCount == 1)
    }
}
