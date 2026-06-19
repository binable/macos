import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginService {

    static let shared = LaunchAtLoginService()
    private init() {}

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration can fail if already registered / unregistered — not critical
        }
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
