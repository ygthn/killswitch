import Foundation
import AppKit

struct AppProcessInfo: Identifiable, Equatable {
    let id: pid_t
    let name: String
    let icon: NSImage?
    var isNotResponding: Bool

    static func == (lhs: AppProcessInfo, rhs: AppProcessInfo) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isNotResponding == rhs.isNotResponding
    }
}
