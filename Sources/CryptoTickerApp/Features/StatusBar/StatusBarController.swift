import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private enum Layout {
        static let controlWidth: CGFloat = 228
        static let controlHeight: CGFloat = 34
        static let horizontalInset: CGFloat = 18
        static let itemSpacing: CGFloat = 8
        static let minTextFieldWidth: CGFloat = 96
        static let customRowWidth: CGFloat = 260
        static let customRowHeight: CGFloat = 26
        static let customRowHorizontalInset: CGFloat = 12
    }

    private let appState: AppState
    private let coordinator: any TickerCoordinating
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()
    private weak var customSymbolTextField: NSTextField?

    init(
        appState: AppState,
        coordinator: any TickerCoordinating
    ) {
        self.appState = appState
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        menu.delegate = self
        configureStatusItem()
        refreshUI()
        bindAppState()
    }

    private func configureStatusItem() {
        statusItem.button?.title = appState.statusTitle
        statusItem.button?.toolTip = AppCopy.statusItemTooltip
        statusItem.menu = menu
    }

    private func refreshUI() {
        statusItem.button?.title = appState.statusTitle
        rebuildMenuItems()
        menu.update()
    }

    private func rebuildMenuItems() {
        menu.removeAllItems()

        let headerItem = NSMenuItem(title: AppCopy.menuHeaderTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false

        let builtinSectionItem = NSMenuItem(title: AppCopy.menuBuiltinSectionTitle, action: nil, keyEquivalent: "")
        builtinSectionItem.isEnabled = false

        menu.items = [headerItem, .separator(), builtinSectionItem]

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
                menu.addItem(makeCustomSymbolRowItem(symbol))
            }
        }

        menu.addItem(.separator())
        let refreshSectionItem = NSMenuItem(title: AppCopy.menuRefreshSectionTitle, action: nil, keyEquivalent: "")
        refreshSectionItem.isEnabled = false
        menu.addItem(refreshSectionItem)

        for preset in AppConfiguration.refreshIntervalPresets {
            let presetItem = NSMenuItem(
                title: "\(preset) 秒",
                action: #selector(selectRefreshIntervalPreset),
                keyEquivalent: ""
            )
            presetItem.target = self
            presetItem.representedObject = preset
            presetItem.state = Int(appState.refreshInterval) == preset ? .on : .off
            menu.addItem(presetItem)
        }

        let quitItem = NSMenuItem(
            title: AppCopy.quitMenuTitle,
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self

        menu.addItem(.separator())
        menu.addItem(quitItem)
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

    private func makeCustomSymbolRowItem(_ symbol: String) -> NSMenuItem {
        let item = NSMenuItem()
        let rowView = CustomSymbolRowView(
            symbol: symbol,
            isSelected: appState.selectedSymbol == symbol,
            width: Layout.customRowWidth,
            height: Layout.customRowHeight,
            horizontalInset: Layout.customRowHorizontalInset
        )
        rowView.onSelect = { [weak self] in
            self?.coordinator.selectSymbol(symbol)
        }
        rowView.onDeleteConfirmed = { [weak self] in
            guard let self else {
                return
            }
            _ = self.coordinator.removeCustomSymbol(symbol)
        }
        item.view = rowView
        return item
    }

    private func makeCustomSymbolInputView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: Layout.controlWidth, height: Layout.controlHeight))
        container.translatesAutoresizingMaskIntoConstraints = false

        let textField = HoverCursorTextField()
        textField.placeholderString = AppCopy.menuCustomInputPlaceholder
        textField.target = self
        textField.action = #selector(addCustomSymbolFromTextField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let applyButton = HoverCursorButton(
            title: AppCopy.menuAddCustomSymbolTitle,
            target: self,
            action: #selector(addCustomSymbolFromButton)
        )
        applyButton.bezelStyle = .rounded
        applyButton.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(textField)
        container.addSubview(applyButton)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Layout.controlWidth),
            container.heightAnchor.constraint(equalToConstant: Layout.controlHeight),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.horizontalInset),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: applyButton.leadingAnchor, constant: -Layout.itemSpacing),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: Layout.minTextFieldWidth),
            applyButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Layout.horizontalInset),
            applyButton.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        customSymbolTextField = textField
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
    private func selectRefreshIntervalPreset(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? Int else {
            return
        }
        _ = coordinator.updateRefreshInterval(input: String(interval))
    }

    private func applyCustomSymbolInput() {
        guard let customSymbolTextField else {
            return
        }

        let result = coordinator.addCustomSymbol(input: customSymbolTextField.stringValue)
        if case .success = result {
            customSymbolTextField.stringValue = ""
            refreshUI()
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        DispatchQueue.main.async { [weak self] in
            guard
                let self,
                let customSymbolTextField,
                let window = customSymbolTextField.window
            else {
                return
            }
            window.makeFirstResponder(customSymbolTextField)
            customSymbolTextField.selectText(nil)
        }
    }
}

final class HoverCursorButton: NSButton {
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
        super.resetCursorRects()
    }
}

final class HoverCursorTextField: NSTextField {
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .iBeam)
        super.resetCursorRects()
    }
}

final class CustomSymbolRowView: NSView {
    private let symbol: String
    private var isConfirmingDelete = false
    private var trackingArea: NSTrackingArea?

    var onSelect: (() -> Void)?
    var onDeleteConfirmed: (() -> Void)?

    private lazy var symbolButton: NSButton = {
        let button = HoverCursorButton(title: symbolButtonTitle, target: self, action: #selector(selectSymbol))
        button.isBordered = false
        button.alignment = .left
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.lineBreakMode = .byTruncatingTail
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var deleteButton: NSButton = {
        let button = HoverCursorButton(title: AppCopy.inlineDeleteButtonTitle, target: self, action: #selector(enterConfirmDelete))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        button.contentTintColor = .secondaryLabelColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private lazy var confirmButton: NSButton = {
        let button = HoverCursorButton(title: AppCopy.deleteConfirmDeleteButton, target: self, action: #selector(confirmDelete))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        button.contentTintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private lazy var cancelButton: NSButton = {
        let button = HoverCursorButton(title: AppCopy.deleteConfirmCancelButton, target: self, action: #selector(cancelDelete))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        button.contentTintColor = .secondaryLabelColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private lazy var actionContainer: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let symbolButtonTitle: String

    init(symbol: String, isSelected: Bool, width: CGFloat, height: CGFloat, horizontalInset: CGFloat) {
        self.symbol = symbol
        symbolButtonTitle = isSelected ? "✓ \(symbol)" : symbol
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(symbolButton)
        addSubview(actionContainer)
        actionContainer.addSubview(deleteButton)
        actionContainer.addSubview(confirmButton)
        actionContainer.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: height),

            symbolButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            symbolButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolButton.trailingAnchor.constraint(lessThanOrEqualTo: actionContainer.leadingAnchor, constant: -8),

            actionContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
            actionContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionContainer.heightAnchor.constraint(equalTo: heightAnchor),
            actionContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),

            deleteButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            cancelButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            confirmButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8),
            confirmButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !isConfirmingDelete else {
            return
        }
        deleteButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard !isConfirmingDelete else {
            return
        }
        deleteButton.isHidden = true
    }

    @objc
    private func selectSymbol() {
        onSelect?()
    }

    @objc
    private func enterConfirmDelete() {
        isConfirmingDelete = true
        deleteButton.isHidden = true
        confirmButton.isHidden = false
        cancelButton.isHidden = false
    }

    @objc
    private func confirmDelete() {
        onDeleteConfirmed?()
    }

    @objc
    private func cancelDelete() {
        isConfirmingDelete = false
        confirmButton.isHidden = true
        cancelButton.isHidden = true
        deleteButton.isHidden = true
    }
}
