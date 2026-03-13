import Foundation

@MainActor
protocol TickerCoordinating: AnyObject {
    func start()
    func stop()
    func selectSymbol(_ symbol: String)
    func addCustomSymbol(input: String) -> AppState.SymbolMutationResult
    func removeCustomSymbol(_ symbol: String) -> Bool
    func updateRefreshInterval(input: String) -> AppState.IntervalMutationResult
}

@MainActor
final class TickerCoordinator: TickerCoordinating {
    private let appState: AppState
    private let priceProvider: any PriceProviding
    private let configurationProvider: any AppConfigurationProviding
    private let refreshScheduler: any RefreshScheduling
    private var refreshTask: Task<Void, Never>?
    private var hasPersistedNormalizedRefreshInterval = false

    init(
        appState: AppState,
        priceProvider: any PriceProviding,
        configurationProvider: any AppConfigurationProviding,
        refreshScheduler: any RefreshScheduling
    ) {
        self.appState = appState
        self.priceProvider = priceProvider
        self.configurationProvider = configurationProvider
        self.refreshScheduler = refreshScheduler
    }

    func start() {
        if appState.didNormalizeRefreshIntervalFromPersistedValue, !hasPersistedNormalizedRefreshInterval {
            persistConfiguration()
            hasPersistedNormalizedRefreshInterval = true
        }
        restartRefreshSchedule()
        refreshNow()
    }

    func stop() {
        refreshScheduler.stop()
        refreshTask?.cancel()
    }

    func selectSymbol(_ symbol: String) {
        appState.selectSymbol(symbol)
        persistConfiguration()
        refreshNow()
    }

    func addCustomSymbol(input: String) -> AppState.SymbolMutationResult {
        let result = appState.addCustomSymbol(input: input)
        switch result {
        case .success:
            persistConfiguration()
        case .invalidInput:
            appState.setDetailMessage(AppCopy.symbolInputInvalidMessage)
        case .duplicate:
            appState.setDetailMessage(AppCopy.symbolInputDuplicateMessage)
        }
        return result
    }

    func removeCustomSymbol(_ symbol: String) -> Bool {
        let removed = appState.removeCustomSymbol(symbol)
        if removed {
            persistConfiguration()
            refreshNow()
        }
        return removed
    }

    func updateRefreshInterval(input: String) -> AppState.IntervalMutationResult {
        let result = appState.updateRefreshInterval(input: input)
        switch result {
        case .success:
            persistConfiguration()
            restartRefreshSchedule()
        case .invalidFormat:
            appState.setDetailMessage(AppCopy.refreshIntervalInvalidFormatMessage)
        case .outOfRange:
            appState.setDetailMessage(AppCopy.refreshIntervalOutOfRangeMessage)
        }
        return result
    }

    private func restartRefreshSchedule() {
        refreshScheduler.stop()
        refreshScheduler.start(interval: appState.refreshInterval) { [weak self] in
            guard let self else {
                return
            }
            Task { @MainActor in
                self.refreshNow()
            }
        }
    }

    private func refreshNow() {
        let symbol = appState.selectedSymbol
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let snapshot = try await self.priceProvider.currentSnapshot(for: symbol)
                await MainActor.run {
                    self.appState.applyPrice(snapshot)
                }
            } catch {
                await MainActor.run {
                    self.appState.applyPriceError()
                }
            }
        }
    }

    private func persistConfiguration() {
        configurationProvider.saveConfiguration(
            selectedSymbol: appState.selectedSymbol,
            customSymbols: appState.customSymbols,
            refreshInterval: appState.refreshInterval
        )
    }
}
