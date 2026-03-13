import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var statusTitle: String
    @Published private(set) var detailMessage: String

    init(
        statusTitle: String = AppCopy.defaultStatusTitle,
        detailMessage: String = AppCopy.defaultDetailMessage
    ) {
        self.statusTitle = statusTitle
        self.detailMessage = detailMessage
    }

    func applyPlaceholder(configuration: AppConfiguration, snapshot: PriceSnapshot?) {
        statusTitle = configuration.defaultAsset.symbol

        if let snapshot {
            detailMessage = "\(snapshot.asset.displayName): \(snapshot.formattedPrice)"
        } else {
            detailMessage = configuration.placeholderStatusMessage
        }
    }
}
