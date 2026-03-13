import Foundation

enum StubLaunchAtLoginError: Error {
    case updateFailed
}

@MainActor
final class StubLaunchAtLoginManager: LaunchAtLoginManaging {
    var isEnabled: Bool
    var requiresApproval: Bool
    var shouldThrow = false

    init(
        isEnabled: Bool = false,
        requiresApproval: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.requiresApproval = requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if shouldThrow {
            throw StubLaunchAtLoginError.updateFailed
        }
        isEnabled = enabled
    }
}
