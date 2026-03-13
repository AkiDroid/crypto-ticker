import Foundation

enum StubPriceProviderError: Error {
    case notImplemented
}

final class StubPriceProvider: PriceProviding {
    func currentSnapshot(for asset: CryptoAsset) throws -> PriceSnapshot? {
        nil
    }
}
