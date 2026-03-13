@MainActor
protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    var requiresApproval: Bool { get }

    func setEnabled(_ enabled: Bool) throws
}
