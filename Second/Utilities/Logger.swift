import Foundation
import os.log

/// Structured logging utility (no secrets)
class Logger {

    enum Level {
        case debug, info, warning, error
    }

    private static let subsystem = "com.second.totp"
    private static let log = OSLog(subsystem: subsystem, category: "general")

    static func debug(_ message: String) {
        os_log("%{public}@", log: log, type: .debug, message)
    }

    static func info(_ message: String) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    static func warning(_ message: String) {
        os_log("%{public}@", log: log, type: .default, message)
    }

    static func error(_ message: String) {
        os_log("%{public}@", log: log, type: .error, message)
    }
}
