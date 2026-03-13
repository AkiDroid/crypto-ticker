@MainActor
final class AppBootstrapper {
    private let coordinator: any TickerCoordinating

    init(coordinator: any TickerCoordinating) {
        self.coordinator = coordinator
    }

    func start() {
        coordinator.start()
    }

    func stop() {
        coordinator.stop()
    }
}
