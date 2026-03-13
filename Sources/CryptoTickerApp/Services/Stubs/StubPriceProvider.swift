import Foundation

enum StubPriceProviderError: Error {
    case notImplemented
}

final class StubPriceProvider: PriceProviding {
    func currentSnapshot(for symbol: String) async throws -> PriceSnapshot {
        PriceSnapshot(
            symbol: symbol,
            priceText: "0.00",
            capturedAt: Date()
        )
    }
}
