import Foundation

@MainActor
final class TimerRefreshScheduler: RefreshScheduling {
    private var timer: Timer?
    private var action: (() -> Void)?

    func start(interval: TimeInterval, _ action: @escaping () -> Void) {
        stop()
        self.action = action
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        action = nil
    }

    @objc
    private func handleTimerTick() {
        action?()
    }
}
