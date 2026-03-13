import Foundation

struct AppConfiguration: Equatable {
    let defaultAsset: CryptoAsset
    let refreshInterval: TimeInterval
    let placeholderStatusMessage: String
}
