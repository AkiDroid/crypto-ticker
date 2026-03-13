import Testing
@testable import CryptoTickerApp

struct StubServicesTests {
    @Test
    func stubConfigurationProvidesDefaultAsset() {
        let configuration = StubAppConfigurationProvider().loadConfiguration()

        #expect(configuration.defaultAsset.symbol == "BTC")
        #expect(configuration.defaultAsset.displayName == "Bitcoin")
        #expect(configuration.placeholderStatusMessage == AppCopy.defaultDetailMessage)
    }

    @Test
    func stubPriceProviderReturnsNoSnapshot() throws {
        let snapshot = try StubPriceProvider().currentSnapshot(
            for: CryptoAsset(symbol: "BTC", displayName: "Bitcoin")
        )

        #expect(snapshot == nil)
    }
}
