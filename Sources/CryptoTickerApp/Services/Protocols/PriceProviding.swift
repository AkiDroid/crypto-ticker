protocol PriceProviding {
    func currentSnapshot(for asset: CryptoAsset) throws -> PriceSnapshot?
}
