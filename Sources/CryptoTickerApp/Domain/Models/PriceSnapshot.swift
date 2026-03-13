import Foundation

struct PriceSnapshot: Equatable {
    let symbol: String
    let priceText: String
    let capturedAt: Date

    var formattedPrice: String {
        guard let value = Double(priceText) else {
            return priceText
        }
        return String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }
}
