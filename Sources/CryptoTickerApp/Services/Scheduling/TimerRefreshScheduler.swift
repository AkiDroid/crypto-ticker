import Foundation

@MainActor
final class TimerRefreshScheduler: RefreshScheduling {
    private var timer: Timer?
    private var action: (() -> Void)?

    func start(interval: TimeInterval, _ action: @escaping () -> Void) {
        stop()
        self.action = action
        let timer = Timer(
            timeInterval: interval,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
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
