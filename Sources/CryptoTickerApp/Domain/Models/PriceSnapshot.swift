import Foundation

struct PriceSnapshot: Equatable {
    let symbol: String
    let priceText: String
    let capturedAt: Date

    var formattedPrice: String {
        priceText
    }
}
