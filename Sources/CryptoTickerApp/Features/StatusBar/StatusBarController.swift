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
    private weak var inputTextField: NSTextField?

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

        let inputSectionItem = NSMenuItem(title: AppCopy.menuInputSectionTitle, action: nil, keyEquivalent: "")
        inputSectionItem.isEnabled = false

        let inputItem = NSMenuItem()
        inputItem.view = makeInputView()

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
            inputSectionItem,
            inputItem,
            .separator(),
            quitItem
        ]

        statusItem.menu = menu
    }

    private func makeInputView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 34))
        container.translatesAutoresizingMaskIntoConstraints = false

        let textField = NSTextField()
        textField.placeholderString = AppCopy.menuInputPlaceholder
        textField.target = self
        textField.action = #selector(applyInputFromTextField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let applyButton = NSButton(
            title: AppCopy.menuApplyInputTitle,
            target: self,
            action: #selector(applyInputFromButton)
        )
        applyButton.bezelStyle = .rounded
        applyButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(textField)
        container.addSubview(applyButton)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 240),
            container.heightAnchor.constraint(equalToConstant: 34),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: applyButton.leadingAnchor, constant: -8),
            applyButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            applyButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        inputTextField = textField
        return container
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

    @objc
    private func applyInputFromTextField() {
        guard let inputTextField else {
            return
        }

        appState.updateStatusTitle(input: inputTextField.stringValue)
    }

    @objc
    private func applyInputFromButton() {
        applyInputFromTextField()
    }
}
