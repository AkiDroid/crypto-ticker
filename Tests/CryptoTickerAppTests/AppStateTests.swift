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
    func updateRefreshIntervalHandlesBounds() {
        let appState = AppState()

        let tooSmall = appState.updateRefreshInterval(input: "0")
        let lowerBound = appState.updateRefreshInterval(input: "1")
        let upperBound = appState.updateRefreshInterval(input: "300")
        let tooLarge = appState.updateRefreshInterval(input: "301")
        let invalid = appState.updateRefreshInterval(input: "abc")

        #expect(tooSmall == .outOfRange)
        #expect(lowerBound == .success(1))
        #expect(upperBound == .success(300))
        #expect(tooLarge == .outOfRange)
        #expect(invalid == .invalidFormat)
    }

    @Test
    func applyPriceUsesBaseSymbolInStatusTitle() {
        let appState = AppState()

        appState.applyPrice(
            PriceSnapshot(
                symbol: "BTCUSDT",
                priceText: "65000.12",
                capturedAt: .now
            )
        )

        #expect(appState.statusTitle == "BTC 65000.12")
    }
}
