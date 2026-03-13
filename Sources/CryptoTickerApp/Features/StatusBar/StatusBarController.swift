import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let appState: AppState
    private let coordinator: any TickerCoordinating
    private let statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()
    private weak var customSymbolTextField: NSTextField?
    private weak var refreshIntervalTextField: NSTextField?

    init(
        appState: AppState,
        coordinator: any TickerCoordinating
    ) {
        self.appState = appState
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        refreshUI()
        bindAppState()
    }

    private func configureStatusItem() {
        statusItem.button?.title = appState.statusTitle
        statusItem.button?.toolTip = AppCopy.statusItemTooltip
    }

    private func refreshUI() {
        statusItem.button?.title = appState.statusTitle
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let headerItem = NSMenuItem(title: AppCopy.menuHeaderTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false

        let detailItem = NSMenuItem(
            title: "\(AppCopy.menuDetailPrefix)：\(appState.detailMessage)",
            action: nil,
            keyEquivalent: ""
        )
        detailItem.isEnabled = false

        let builtinSectionItem = NSMenuItem(title: AppCopy.menuBuiltinSectionTitle, action: nil, keyEquivalent: "")
        builtinSectionItem.isEnabled = false

        menu.items = [headerItem, .separator(), detailItem, .separator(), builtinSectionItem]

        for symbol in appState.builtinSymbols {
            menu.addItem(makeSymbolItem(symbol))
        }

        menu.addItem(.separator())
        let customSectionItem = NSMenuItem(title: AppCopy.menuCustomSectionTitle, action: nil, keyEquivalent: "")
        customSectionItem.isEnabled = false
        menu.addItem(customSectionItem)

        let customInputItem = NSMenuItem()
        customInputItem.view = makeCustomSymbolInputView()
        menu.addItem(customInputItem)

        if appState.customSymbols.isEmpty {
            let noCustomItem = NSMenuItem(title: AppCopy.menuNoCustomSymbols, action: nil, keyEquivalent: "")
            noCustomItem.isEnabled = false
            menu.addItem(noCustomItem)
        } else {
            for symbol in appState.customSymbols {
                menu.addItem(makeSymbolItem(symbol))
            }
        }

        if !appState.customSymbols.isEmpty {
            menu.addItem(.separator())
            let deleteSectionItem = NSMenuItem(title: AppCopy.menuDeleteSectionTitle, action: nil, keyEquivalent: "")
            deleteSectionItem.isEnabled = false
            menu.addItem(deleteSectionItem)

            for symbol in appState.customSymbols {
                let deleteItem = NSMenuItem(
                    title: "\(AppCopy.deleteConfirmDeleteButton) \(symbol)",
                    action: #selector(confirmDeleteCustomSymbol),
                    keyEquivalent: ""
                )
                deleteItem.target = self
                deleteItem.representedObject = symbol
                menu.addItem(deleteItem)
            }
        }

        menu.addItem(.separator())
        let refreshSectionItem = NSMenuItem(title: AppCopy.menuRefreshSectionTitle, action: nil, keyEquivalent: "")
        refreshSectionItem.isEnabled = false
        menu.addItem(refreshSectionItem)

        let refreshItem = NSMenuItem()
        refreshItem.view = makeRefreshIntervalInputView()
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(
            title: AppCopy.quitMenuTitle,
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self

        menu.addItem(.separator())
        menu.addItem(quitItem)
        return menu
    }

    private func makeSymbolItem(_ symbol: String) -> NSMenuItem {
        let item = NSMenuItem(
            title: symbol,
            action: #selector(selectSymbolFromMenuItem),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = symbol
        item.state = appState.selectedSymbol == symbol ? .on : .off
        return item
    }

    private func makeCustomSymbolInputView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 34))
        container.translatesAutoresizingMaskIntoConstraints = false

        let textField = NSTextField()
        textField.placeholderString = AppCopy.menuCustomInputPlaceholder
        textField.target = self
        textField.action = #selector(addCustomSymbolFromTextField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let applyButton = NSButton(
            title: AppCopy.menuAddCustomSymbolTitle,
            target: self,
            action: #selector(addCustomSymbolFromButton)
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

        customSymbolTextField = textField
        return container
    }

    private func makeRefreshIntervalInputView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 34))
        container.translatesAutoresizingMaskIntoConstraints = false

        let textField = NSTextField(string: String(Int(appState.refreshInterval)))
        textField.placeholderString = AppCopy.menuRefreshInputPlaceholder
        textField.target = self
        textField.action = #selector(applyRefreshIntervalFromTextField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let applyButton = NSButton(
            title: AppCopy.menuApplyRefreshTitle,
            target: self,
            action: #selector(applyRefreshIntervalFromButton)
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

        refreshIntervalTextField = textField
        return container
    }

    private func bindAppState() {
        let updates: [AnyPublisher<Void, Never>] = [
            appState.$statusTitle.map { _ in () }.eraseToAnyPublisher(),
            appState.$detailMessage.map { _ in () }.eraseToAnyPublisher(),
            appState.$selectedSymbol.map { _ in () }.eraseToAnyPublisher(),
            appState.$customSymbols.map { _ in () }.eraseToAnyPublisher(),
            appState.$refreshInterval.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(updates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.refreshUI()
            }
            .store(in: &cancellables)
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }

    @objc
    private func selectSymbolFromMenuItem(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else {
            return
        }

        coordinator.selectSymbol(symbol)
    }

    @objc
    private func addCustomSymbolFromTextField() {
        applyCustomSymbolInput()
    }

    @objc
    private func addCustomSymbolFromButton() {
        applyCustomSymbolInput()
    }

    @objc
    private func applyRefreshIntervalFromTextField() {
        applyRefreshIntervalInput()
    }

    @objc
    private func applyRefreshIntervalFromButton() {
        applyRefreshIntervalInput()
    }

    @objc
    private func confirmDeleteCustomSymbol(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else {
            return
        }

        let alert = NSAlert()
        alert.messageText = AppCopy.deleteConfirmTitle
        alert.informativeText = "\(AppCopy.deleteConfirmMessagePrefix) \(symbol)？"
        alert.addButton(withTitle: AppCopy.deleteConfirmDeleteButton)
        alert.addButton(withTitle: AppCopy.deleteConfirmCancelButton)

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return
        }

        _ = coordinator.removeCustomSymbol(symbol)
    }

    private func applyCustomSymbolInput() {
        guard let customSymbolTextField else {
            return
        }

        let result = coordinator.addCustomSymbol(input: customSymbolTextField.stringValue)
        if case .success = result {
            customSymbolTextField.stringValue = ""
        }
    }

    private func applyRefreshIntervalInput() {
        guard let refreshIntervalTextField else {
            return
        }

        _ = coordinator.updateRefreshInterval(input: refreshIntervalTextField.stringValue)
    }
}
