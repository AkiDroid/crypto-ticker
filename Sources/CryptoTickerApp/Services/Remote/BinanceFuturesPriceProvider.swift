import Foundation

enum BinanceFuturesPriceProviderError: Error {
    case invalidURL
    case invalidResponse
    case invalidPayload
}

final class BinanceFuturesPriceProvider: PriceProviding {
    private struct TickerPriceResponse: Decodable {
        let symbol: String
        let price: String
    }

    private let session: URLSession
    private let endpoint: URL?
    private let decoder = JSONDecoder()

    init(
        session: URLSession = .shared,
        endpoint: URL? = URL(string: "https://fapi.binance.com/fapi/v1/ticker/price")
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func currentSnapshot(for symbol: String) async throws -> PriceSnapshot {
        guard let endpoint else {
            throw BinanceFuturesPriceProviderError.invalidURL
        }
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw BinanceFuturesPriceProviderError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        guard let requestURL = components.url else {
            throw BinanceFuturesPriceProviderError.invalidURL
        }

        let (data, response) = try await session.data(from: requestURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw BinanceFuturesPriceProviderError.invalidResponse
        }

        let payload = try decoder.decode(TickerPriceResponse.self, from: data)
        guard !payload.price.isEmpty else {
            throw BinanceFuturesPriceProviderError.invalidPayload
        }

        return PriceSnapshot(
            symbol: payload.symbol,
            priceText: payload.price,
            capturedAt: Date()
        )
    }
}
