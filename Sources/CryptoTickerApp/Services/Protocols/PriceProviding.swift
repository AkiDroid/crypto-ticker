@MainActor
protocol PriceProviding {
    func currentSnapshot(for symbol: String) async throws -> PriceSnapshot
}
