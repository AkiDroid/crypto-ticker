final class NoopRefreshScheduler: RefreshScheduling {
    private(set) var isRunning = false

    func start(_ action: @escaping () -> Void) {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }
}
