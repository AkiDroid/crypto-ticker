import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    enum SymbolMutationResult: Equatable {
        case success(String)
        case invalidInput
        case duplicate
    }

    enum IntervalMutationResult: Equatable {
        case success(TimeInterval)
        case invalidFormat
        case outOfRange
    }

    @Published private(set) var statusTitle: String
    @Published private(set) var detailMessage: String
    @Published private(set) var selectedSymbol: String
    @Published private(set) var customSymbols: [String]
    @Published private(set) var refreshInterval: TimeInterval

    let builtinSymbols: [String]
    let didNormalizeRefreshIntervalFromPersistedValue: Bool

    init(
        statusTitle: String = AppCopy.defaultStatusTitle,
        detailMessage: String = AppCopy.defaultDetailMessage,
        selectedSymbol: String = AppConfiguration.default.selectedSymbol,
        customSymbols: [String] = AppConfiguration.default.customSymbols,
        refreshInterval: TimeInterval = AppConfiguration.default.refreshInterval,
        builtinSymbols: [String] = AppConfiguration.default.builtinSymbols
    ) {
        let normalizedBuiltins = AppState.normalizedUniqueSymbols(from: builtinSymbols)
        let resolvedBuiltins = normalizedBuiltins.isEmpty ? AppConfiguration.default.builtinSymbols : normalizedBuiltins
        let normalizedCustoms = AppState.normalizedUniqueSymbols(from: customSymbols)
            .filter { !resolvedBuiltins.contains($0) }
        let allSymbols = resolvedBuiltins + normalizedCustoms
        let normalizedSelected = AppState.normalizeSymbol(selectedSymbol)

        let normalizedRefreshResult = AppState.normalizedRefreshInterval(refreshInterval)

        self.builtinSymbols = resolvedBuiltins
        self.customSymbols = normalizedCustoms
        self.selectedSymbol = allSymbols.contains(normalizedSelected) ? normalizedSelected : resolvedBuiltins[0]
        self.refreshInterval = normalizedRefreshResult.interval
        self.didNormalizeRefreshIntervalFromPersistedValue = normalizedRefreshResult.didNormalize
        self.statusTitle = statusTitle
        self.detailMessage = detailMessage
        self.statusTitle = "\(baseSymbol(of: self.selectedSymbol)) --"
    }

    convenience init(configuration: AppConfiguration) {
        self.init(
            selectedSymbol: configuration.selectedSymbol,
            customSymbols: configuration.customSymbols,
            refreshInterval: configuration.refreshInterval,
            builtinSymbols: configuration.builtinSymbols
        )
    }

    var allSymbols: [String] {
        builtinSymbols + customSymbols
    }

    func selectSymbol(_ symbol: String) {
        let normalized = Self.normalizeSymbol(symbol)
        guard allSymbols.contains(normalized) else {
            return
        }

        selectedSymbol = normalized
        statusTitle = "\(baseSymbol(of: normalized)) --"
        detailMessage = "已切换到 \(normalized)，正在刷新价格"
    }

    func addCustomSymbol(input: String) -> SymbolMutationResult {
        let normalized = Self.normalizeSymbol(input)
        guard !normalized.isEmpty else {
            return .invalidInput
        }
        guard !allSymbols.contains(normalized) else {
            return .duplicate
        }

        customSymbols.append(normalized)
        detailMessage = "\(AppCopy.customSymbolAddedMessage) \(normalized)"
        return .success(normalized)
    }

    func removeCustomSymbol(_ symbol: String) -> Bool {
        let normalized = Self.normalizeSymbol(symbol)
        guard !builtinSymbols.contains(normalized) else {
            detailMessage = AppCopy.symbolDeleteForbiddenMessage
            return false
        }
        guard let targetIndex = customSymbols.firstIndex(of: normalized) else {
            return false
        }

        customSymbols.remove(at: targetIndex)
        if selectedSymbol == normalized {
            selectedSymbol = builtinSymbols[0]
            statusTitle = "\(baseSymbol(of: selectedSymbol)) --"
        }
        detailMessage = "\(AppCopy.customSymbolDeletedMessage) \(normalized)"
        return true
    }

    func updateRefreshInterval(input: String) -> IntervalMutationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let interval = Int(trimmed) else {
            return .invalidFormat
        }
        guard AppConfiguration.refreshIntervalPresets.contains(interval) else {
            return .outOfRange
        }

        refreshInterval = TimeInterval(interval)
        detailMessage = "\(AppCopy.refreshIntervalUpdatedMessage) \(interval) 秒"
        return .success(refreshInterval)
    }

    func applyPrice(_ snapshot: PriceSnapshot) {
        let symbol = Self.normalizeSymbol(snapshot.symbol)
        let displaySymbol = baseSymbol(of: symbol)
        statusTitle = "\(displaySymbol) \(snapshot.formattedPrice)"
        detailMessage = "\(symbol): \(snapshot.formattedPrice)"
    }

    func applyPriceError(_ message: String = AppCopy.priceFetchFailedMessage) {
        detailMessage = message
    }

    func setDetailMessage(_ message: String) {
        detailMessage = message
    }

    static func normalizeSymbol(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private static func normalizedUniqueSymbols(from symbols: [String]) -> [String] {
        var seen = Set<String>()
        return symbols
            .map(Self.normalizeSymbol)
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    private static func normalizedRefreshInterval(_ interval: TimeInterval) -> (interval: TimeInterval, didNormalize: Bool) {
        let presets = AppConfiguration.refreshIntervalPresets
        let current = Int(interval.rounded())
        if presets.contains(current) {
            return (TimeInterval(current), false)
        }

        let nearest = presets.min { lhs, rhs in
            let lhsDistance = abs(lhs - current)
            let rhsDistance = abs(rhs - current)
            if lhsDistance == rhsDistance {
                return lhs < rhs
            }
            return lhsDistance < rhsDistance
        } ?? Int(AppConfiguration.defaultRefreshInterval)

        return (TimeInterval(nearest), true)
    }

    private func baseSymbol(of symbol: String) -> String {
        if symbol.hasSuffix("USDT") && symbol.count > 4 {
            return String(symbol.dropLast(4))
        }
        return symbol
    }
}
