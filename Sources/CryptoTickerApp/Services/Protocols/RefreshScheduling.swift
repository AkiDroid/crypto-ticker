import Foundation

@MainActor
protocol RefreshScheduling {
    func start(interval: TimeInterval, _ action: @escaping () -> Void)
    func stop()
}
