import SwiftUI

@main
struct KillswitchApp: App {
    @StateObject private var processService = ProcessService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(processService: processService)
        } label: {
            Image(systemName: "bolt.trianglebadge.exclamationmark")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
