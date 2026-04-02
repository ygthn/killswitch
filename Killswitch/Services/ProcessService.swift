import Foundation
import AppKit

enum QuitStatus: Equatable {
    case idle
    case quitting
    case failed(pid_t)
}

@MainActor
final class ProcessService: ObservableObject {
    @Published var processes: [AppProcessInfo] = []
    @Published var quitStatus: QuitStatus = .idle

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
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            processes.removeAll { $0.id == pid }
            return
        }

        quitStatus = .quitting

        // First attempt: graceful terminate (Apple Event - works in sandbox)
        app.terminate()

        // Wait and retry with escalation
        Task { @MainActor in
            // Wait 2 seconds, check if terminated
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            if app.isTerminated {
                processes.removeAll { $0.id == pid }
                quitStatus = .idle
                snapshot()
                return
            }

            // Second attempt
            app.forceTerminate()

            try? await Task.sleep(nanoseconds: 1_500_000_000)

            if app.isTerminated {
                processes.removeAll { $0.id == pid }
                quitStatus = .idle
                snapshot()
                return
            }

            // Failed - show escalation prompt
            quitStatus = .failed(pid)
            snapshot()
        }
    }

    func gracefulQuit(pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.terminate()
        }
        processes.removeAll { $0.id == pid }
    }

    func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        quitStatus = .idle
    }

    func dismissFailure() {
        quitStatus = .idle
    }
}
