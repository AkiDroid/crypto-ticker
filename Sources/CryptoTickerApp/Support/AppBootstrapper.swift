@MainActor
final class AppBootstrapper {
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func start() {
        let configuration = container.configurationProvider.loadConfiguration()
        let snapshot = try? container.priceProvider.currentSnapshot(for: configuration.defaultAsset)
        container.appState.applyPlaceholder(configuration: configuration, snapshot: snapshot)
        container.refreshScheduler.start {}
    }
}
