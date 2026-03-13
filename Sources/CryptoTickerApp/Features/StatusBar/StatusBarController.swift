import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private enum MenuItemTag {
        static let detail = 1001
    }

    private let appState: AppState
    private let statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        configureMenu()
        bindAppState()
    }

    private func configureStatusItem() {
        statusItem.button?.title = appState.statusTitle
        statusItem.button?.toolTip = AppCopy.statusItemTooltip
    }

    private func configureMenu() {
        let menu = NSMenu()

        let headerItem = NSMenuItem(title: AppCopy.menuHeaderTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false

        let detailItem = NSMenuItem(title: appState.detailMessage, action: nil, keyEquivalent: "")
        detailItem.isEnabled = false
        detailItem.tag = MenuItemTag.detail

        let quitItem = NSMenuItem(
            title: AppCopy.quitMenuTitle,
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self

        menu.items = [
            headerItem,
            .separator(),
            detailItem,
            .separator(),
            quitItem
        ]

        statusItem.menu = menu
    }

    private func bindAppState() {
        appState.$statusTitle
            .combineLatest(appState.$detailMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] title, detail in
                self?.statusItem.button?.title = title
                self?.statusItem.menu?.item(withTag: MenuItemTag.detail)?.title = detail
            }
            .store(in: &cancellables)
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }
}
