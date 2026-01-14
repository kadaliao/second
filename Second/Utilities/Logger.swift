//
//  Logger.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import Foundation
import os.log

/// Structured logging utility (no secrets logged)
class Logger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.second.totp"
    private static let logger = os.Logger(subsystem: subsystem, category: "general")

    enum Level {
        case debug
        case info
        case warning
        case error
    }

    static func debug(_ message: String) {
        logger.debug("\(message)")
    }

    static func info(_ message: String) {
        logger.info("\(message)")
    }

    static func warning(_ message: String) {
        logger.warning("\(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message)")
    }

    static func log(_ level: Level, _ message: String) {
        switch level {
        case .debug:
            debug(message)
        case .info:
            info(message)
        case .warning:
            warning(message)
        case .error:
            error(message)
        }
    }
}
