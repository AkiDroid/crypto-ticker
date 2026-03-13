import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let container = AppContainer.bootstrap()
    private var statusBarController: StatusBarController?
    private var bootstrapper: AppBootstrapper?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let bootstrapper = AppBootstrapper(container: container)
        bootstrapper.start()
        self.bootstrapper = bootstrapper

        statusBarController = StatusBarController(appState: container.appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.refreshScheduler.stop()
    }
}
