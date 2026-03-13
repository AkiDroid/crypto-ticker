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
        let snapshot = try await StubPriceProvider().currentSnapshot(for: "BTCUSDT")

        #expect(snapshot.symbol == "BTCUSDT")
        #expect(snapshot.formattedPrice == "0.00")
    }

    @Test
    func priceSnapshotFormatsToTwoDecimals() {
        let decimalSnapshot = PriceSnapshot(
            symbol: "BTCUSDT",
            priceText: "65000.1",
            capturedAt: .now
        )
        let integerSnapshot = PriceSnapshot(
            symbol: "ETHUSDT",
            priceText: "65000",
            capturedAt: .now
        )

        #expect(decimalSnapshot.formattedPrice == "65000.10")
        #expect(integerSnapshot.formattedPrice == "65000.00")
    }

    @Test
    func priceSnapshotFallsBackForInvalidText() {
        let snapshot = PriceSnapshot(
            symbol: "SOLUSDT",
            priceText: "N/A",
            capturedAt: .now
        )

        #expect(snapshot.formattedPrice == "N/A")
    }
}
