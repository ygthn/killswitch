import Foundation
import AppKit

@MainActor
final class ProcessService: ObservableObject {
    @Published var processes: [AppProcessInfo] = []

    func snapshot() {
        let runningApps = NSWorkspace.shared.runningApplications

        var list: [AppProcessInfo] = []

        for app in runningApps {
            guard app.activationPolicy == .regular else { continue }

            let pid = app.processIdentifier
            let name = app.localizedName ?? "Unknown"
            let icon = app.icon
            icon?.size = NSSize(width: 32, height: 32)

            list.append(AppProcessInfo(
                id: pid,
                name: name,
                icon: icon,
                isNotResponding: !app.isFinishedLaunching
            ))
        }

        list.sort { a, b in
            if a.isNotResponding != b.isNotResponding { return a.isNotResponding }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        self.processes = list
    }

    func forceQuit(pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.forceTerminate()
        }
        processes.removeAll { $0.id == pid }
    }

    func gracefulQuit(pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.terminate()
        }
        processes.removeAll { $0.id == pid }
    }
}
