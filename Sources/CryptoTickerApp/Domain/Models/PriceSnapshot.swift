import Foundation

struct PriceSnapshot: Equatable {
    let asset: CryptoAsset
    let priceText: String
    let capturedAt: Date

    var formattedPrice: String {
        priceText
    }
}
