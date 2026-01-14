//
//  SecondApp.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI

@main
struct SecondApp: App {
    init() {
        // Enable iCloud sync
        _ = NSUbiquitousKeyValueStore.default
        Logger.info("Second app 已启动")
    }

    var body: some Scene {
        WindowGroup {
            TokenListView()
        }
    }
}
