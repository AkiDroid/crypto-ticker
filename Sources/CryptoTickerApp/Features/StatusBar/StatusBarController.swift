import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private enum Layout {
        static let symbolRowWidth: CGFloat = 228
        static let customRowHeight: CGFloat = 26
        static let symbolRowHorizontalInset: CGFloat = 18
    }

    private let appState: AppState
    private let coordinator: any TickerCoordinating
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()

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
        guard let button = statusItem.button else {
            statusItem.menu = menu
            return
        }
        button.toolTip = AppCopy.statusItemTooltip
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleProportionallyDown
        updateStatusItemAppearance(title: appState.statusTitle, showsErrorIndicator: appState.showsErrorIndicator)
        statusItem.menu = menu
    }

    private func refreshUI() {
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
            menu.addItem(makeSymbolRowItem(symbol, allowsDeletion: false))
        }

        menu.addItem(.separator())
        let customSectionItem = NSMenuItem(title: AppCopy.menuCustomSectionTitle, action: nil, keyEquivalent: "")
        customSectionItem.isEnabled = false
        menu.addItem(customSectionItem)

        let addCustomSymbolItem = NSMenuItem(
            title: AppCopy.menuAddCustomSymbolTitle,
            action: #selector(promptAddCustomSymbol),
            keyEquivalent: ""
        )
        addCustomSymbolItem.target = self
        menu.addItem(addCustomSymbolItem)

        if appState.customSymbols.isEmpty {
            let noCustomItem = NSMenuItem(title: AppCopy.menuNoCustomSymbols, action: nil, keyEquivalent: "")
            noCustomItem.isEnabled = false
            menu.addItem(noCustomItem)
        } else {
            for symbol in appState.customSymbols {
                menu.addItem(makeSymbolRowItem(symbol, allowsDeletion: true))
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

    private func makeSymbolRowItem(_ symbol: String, allowsDeletion: Bool) -> NSMenuItem {
        let item = NSMenuItem()
        let rowView = SymbolRowView(
            symbol: symbol,
            isSelected: appState.selectedSymbol == symbol,
            allowsDeletion: allowsDeletion,
            width: Layout.symbolRowWidth,
            height: Layout.customRowHeight,
            horizontalInset: Layout.symbolRowHorizontalInset
        )
        rowView.onSelect = { [weak self] in
            guard let self else {
                return
            }
            self.coordinator.selectSymbol(symbol)
            self.refreshUI()
        }
        rowView.onDeleteConfirmed = { [weak self] in
            guard let self else {
                return
            }
            let removed = self.coordinator.removeCustomSymbol(symbol)
            if removed {
                self.refreshUI()
            }
        }
        item.view = rowView
        return item
    }

    private func bindAppState() {
        Publishers.CombineLatest(appState.$statusTitle, appState.$showsErrorIndicator)
            .receive(on: RunLoop.main)
            .sink { [weak self] title, showsErrorIndicator in
                self?.updateStatusItemAppearance(title: title, showsErrorIndicator: showsErrorIndicator)
            }
            .store(in: &cancellables)

        let menuStructureUpdates: [AnyPublisher<Void, Never>] = [
            appState.$selectedSymbol.map { _ in () }.eraseToAnyPublisher(),
            appState.$customSymbols.map { _ in () }.eraseToAnyPublisher(),
            appState.$refreshInterval.map { _ in () }.eraseToAnyPublisher()
        ]

        Publishers.MergeMany(menuStructureUpdates)
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
    private func selectRefreshIntervalPreset(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? Int else {
            return
        }
        _ = coordinator.updateRefreshInterval(input: String(interval))
    }

    @objc
    private func promptAddCustomSymbol() {
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        inputField.placeholderString = AppCopy.menuCustomInputPlaceholder

        let alert = NSAlert()
        alert.messageText = AppCopy.addSymbolPromptTitle
        alert.informativeText = AppCopy.addSymbolPromptMessage
        alert.alertStyle = .informational
        alert.accessoryView = inputField
        alert.addButton(withTitle: AppCopy.addSymbolConfirmButton)
        alert.addButton(withTitle: AppCopy.addSymbolCancelButton)

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return
        }

        let result = coordinator.addCustomSymbol(input: inputField.stringValue)
        if case .success = result {
            refreshUI()
        }
    }

    private func updateStatusItemAppearance(title: String, showsErrorIndicator: Bool) {
        guard let button = statusItem.button else {
            return
        }
        button.title = title
        if showsErrorIndicator {
            let image = NSImage(
                systemSymbolName: "exclamationmark.circle.fill",
                accessibilityDescription: "请求失败"
            )
            image?.isTemplate = true
            button.image = image
        } else {
            button.image = nil
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

final class SymbolRowView: NSView {
    private let allowsDeletion: Bool
    private var isConfirmingDelete = false
    private var trackingArea: NSTrackingArea?

    var onSelect: (() -> Void)?
    var onDeleteConfirmed: (() -> Void)?

    private lazy var symbolButton: NSButton = {
        let button = HoverCursorButton(title: symbolButtonTitle, target: self, action: #selector(selectSymbol))
        button.isBordered = false
        button.alignment = .left
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.contentTintColor = .labelColor
        button.lineBreakMode = .byTruncatingTail
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var deleteButton: NSButton = {
        let button = HoverCursorButton(title: AppCopy.inlineDeleteButtonTitle, target: self, action: #selector(enterConfirmDelete))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        button.contentTintColor = .labelColor
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
    private var dynamicConstraints: [NSLayoutConstraint] = []

    init(symbol: String, isSelected: Bool, allowsDeletion: Bool, width: CGFloat, height: CGFloat, horizontalInset: CGFloat) {
        self.allowsDeletion = allowsDeletion
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

            deleteButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            cancelButton.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor),

            confirmButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8),
            confirmButton.centerYAnchor.constraint(equalTo: actionContainer.centerYAnchor)
        ])

        if allowsDeletion {
            dynamicConstraints = [
                actionContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
                actionContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
                actionContainer.heightAnchor.constraint(equalTo: heightAnchor),
                actionContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 72)
            ]
        } else {
            dynamicConstraints = [
                actionContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
                actionContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
                actionContainer.heightAnchor.constraint(equalTo: heightAnchor),
                actionContainer.widthAnchor.constraint(equalToConstant: 0)
            ]
            actionContainer.isHidden = true
        }
        NSLayoutConstraint.activate(dynamicConstraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        guard allowsDeletion else {
            if let trackingArea {
                removeTrackingArea(trackingArea)
                self.trackingArea = nil
            }
            super.updateTrackingAreas()
            return
        }

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
        guard allowsDeletion, !isConfirmingDelete else {
            return
        }
        deleteButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard allowsDeletion, !isConfirmingDelete else {
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
        guard allowsDeletion else {
            return
        }
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
