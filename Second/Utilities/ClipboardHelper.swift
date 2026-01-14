//
//  ClipboardHelper.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import UIKit

/// Clipboard helper with toast notification
class ClipboardHelper {

    static func copy(_ text: String) {
        UIPasteboard.general.string = text

        // Haptic feedback for successful copy
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        Logger.info("已复制到剪贴板")
    }

    static func showToast(message: String, in view: UIView, duration: TimeInterval = 2.0) {
        let toastLabel = UILabel(frame: CGRect(x: view.frame.size.width/2 - 100, y: view.frame.size.height - 100, width: 200, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14.0)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        view.addSubview(toastLabel)
        
        UIView.animate(withDuration: duration, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }
}
