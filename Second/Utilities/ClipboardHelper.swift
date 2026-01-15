import UIKit

/// Clipboard helper with toast notification
class ClipboardHelper {

    static func copy(_ text: String) {
        UIPasteboard.general.string = text
        Logger.info("Copied to clipboard")
    }
}
