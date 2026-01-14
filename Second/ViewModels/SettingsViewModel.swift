//
//  SettingsViewModel.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import Foundation

/// ViewModel for settings management
class SettingsViewModel: ObservableObject {
    /// App version from Info.plist
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
