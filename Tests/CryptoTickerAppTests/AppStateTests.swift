import Testing
@testable import CryptoTickerApp

@MainActor
struct AppStateTests {
    @Test
    func selectSymbolUpdatesCurrentSelection() {
        let appState = AppState(
            selectedSymbol: "BTCUSDT",
            customSymbols: ["BNBUSDT"]
        )

        appState.selectSymbol("BNBUSDT")

        #expect(appState.selectedSymbol == "BNBUSDT")
        #expect(appState.statusTitle == "BNB --")
    }

    @Test
    func addCustomSymbolRejectsBlankAndDuplicate() {
        let appState = AppState(customSymbols: ["BNBUSDT"])

        let blankResult = appState.addCustomSymbol(input: "   \n")
        let duplicateResult = appState.addCustomSymbol(input: "bnbusdt")

        #expect(blankResult == .invalidInput)
        #expect(duplicateResult == .duplicate)
        #expect(appState.customSymbols == ["BNBUSDT"])
    }

    @Test
    func removeCustomSymbolDoesNotAllowBuiltins() {
        let appState = AppState()

        let removed = appState.removeCustomSymbol("BTCUSDT")

        #expect(removed == false)
        #expect(appState.selectedSymbol == "BTCUSDT")
    }

    @Test
    func updateRefreshIntervalAcceptsOnlyPresetValues() {
        let appState = AppState()

        let invalidSmall = appState.updateRefreshInterval(input: "1")
        let validPreset = appState.updateRefreshInterval(input: "10")
        let invalidCustom = appState.updateRefreshInterval(input: "7")
        let invalidLarge = appState.updateRefreshInterval(input: "300")
        let invalid = appState.updateRefreshInterval(input: "abc")

        #expect(invalidSmall == .outOfRange)
        #expect(validPreset == .success(10))
        #expect(invalidCustom == .outOfRange)
        #expect(invalidLarge == .outOfRange)
        #expect(invalid == .invalidFormat)
    }

    @Test
    func initNormalizesRefreshIntervalToNearestPreset() {
        let lowerNearest = AppState(refreshInterval: 7)
        let upperNearest = AppState(refreshInterval: 28)

        #expect(lowerNearest.refreshInterval == 5)
        #expect(upperNearest.refreshInterval == 30)
        #expect(lowerNearest.didNormalizeRefreshIntervalFromPersistedValue)
        #expect(upperNearest.didNormalizeRefreshIntervalFromPersistedValue)
    }

    @Test
    func applyPriceUsesBaseSymbolInStatusTitle() {
        let appState = AppState()

        appState.applyPrice(
            PriceSnapshot(
                symbol: "BTCUSDT",
                priceText: "65000.1",
                capturedAt: .now
            )
        )

        #expect(appState.statusTitle == "BTC 65000.10")
    }

    @Test
    func showsErrorIndicatorAfterThreeConsecutivePriceFailures() {
        let appState = AppState()

        appState.applyPriceError()
        #expect(appState.showsErrorIndicator == false)

        appState.applyPriceError()
        #expect(appState.showsErrorIndicator == false)

        appState.applyPriceError()

        #expect(appState.showsErrorIndicator == true)
    }

    @Test
    func successfulPriceRefreshClearsErrorIndicator() {
        let appState = AppState()

        appState.applyPriceError()
        appState.applyPriceError()
        appState.applyPriceError()
        appState.applyPrice(
            PriceSnapshot(
                symbol: "BTCUSDT",
                priceText: "65000",
                capturedAt: .now
            )
        )

        #expect(appState.showsErrorIndicator == false)
    }
}
