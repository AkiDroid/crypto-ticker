import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let container = AppContainer.bootstrap()
    private var statusBarController: StatusBarController?
    private var coordinator: TickerCoordinator?
    private var bootstrapper: AppBootstrapper?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let coordinator = TickerCoordinator(
            appState: container.appState,
            priceProvider: container.priceProvider,
            configurationProvider: container.configurationProvider,
            refreshScheduler: container.refreshScheduler
        )
        self.coordinator = coordinator

        let bootstrapper = AppBootstrapper(coordinator: coordinator)
        bootstrapper.start()
        self.bootstrapper = bootstrapper

        statusBarController = StatusBarController(
            appState: container.appState,
            coordinator: coordinator
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        bootstrapper?.stop()
    }
}
