import Testing
@testable import CryptoTickerApp

@MainActor
struct AppStateTests {
    @Test
    func updateStatusTitleSetsTrimmedValue() {
        let appState = AppState(statusTitle: "BTC", detailMessage: "detail")

        appState.updateStatusTitle(input: "  ETH  ")

        #expect(appState.statusTitle == "ETH")
    }

    @Test
    func updateStatusTitleIgnoresBlankInput() {
        let appState = AppState(statusTitle: "BTC", detailMessage: "detail")

        appState.updateStatusTitle(input: "   \n")

        #expect(appState.statusTitle == "BTC")
    }
}
