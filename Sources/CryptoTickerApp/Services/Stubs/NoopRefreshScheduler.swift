import Foundation

final class NoopRefreshScheduler: RefreshScheduling {
    private(set) var isRunning = false
    private(set) var lastInterval: TimeInterval?
    private var action: (() -> Void)?

    func start(interval: TimeInterval, _ action: @escaping () -> Void) {
        isRunning = true
        lastInterval = interval
        self.action = action
    }

    func stop() {
        isRunning = false
        action = nil
    }

    func fire() {
        action?()
    }
}
