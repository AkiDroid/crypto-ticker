import Foundation

enum StubPriceProviderError: Error {
    case notImplemented
}

final class StubPriceProvider: PriceProviding {
    private var queuedResults: [Result<PriceSnapshot, Error>]

    init(queuedResults: [Result<PriceSnapshot, Error>] = []) {
        self.queuedResults = queuedResults
    }

    func currentSnapshot(for symbol: String) async throws -> PriceSnapshot {
        if !queuedResults.isEmpty {
            let result = queuedResults.removeFirst()
            return try result.get()
        }
        return PriceSnapshot(
            symbol: symbol,
            priceText: "0.00",
            capturedAt: Date()
        )
    }
}
