import Testing
@testable import CryptoTickerApp

struct StubServicesTests {
    @Test
    func stubConfigurationProvidesDefaultAsset() {
        let configuration = StubAppConfigurationProvider().loadConfiguration()

        #expect(configuration.selectedSymbol == "BTCUSDT")
        #expect(configuration.builtinSymbols == ["BTCUSDT", "ETHUSDT", "SOLUSDT"])
        #expect(configuration.customSymbols.isEmpty)
    }

    @Test
    func stubPriceProviderReturnsSnapshot() async throws {
        let snapshot = try await StubPriceProvider().currentSnapshot(
            for: "BTCUSDT"
        )

        #expect(snapshot.symbol == "BTCUSDT")
        #expect(snapshot.formattedPrice == "0.00")
    }
}
