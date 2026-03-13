protocol RefreshScheduling {
    func start(_ action: @escaping () -> Void)
    func stop()
}
