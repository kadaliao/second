//
//  SettingsView.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import SwiftUI

/// Settings screen with account sorting, iCloud export, and app version
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            List {
                // Account sorting section
                Section {
                    NavigationLink(destination: TokenSortView()) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.accentColor)
                                .frame(width: 24)

                            Text(L10n.sortAccounts)
                        }
                    }
                } header: {
                    Text(L10n.manage)
                }

                // iCloud section
                Section {
                    NavigationLink(destination: iCloudExportView()) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.accentColor)
                                .frame(width: 24)

                            Text(L10n.iCloudDataExport)
                        }
                    }
                } header: {
                    Text(L10n.data)
                }

                // About section
                Section {
                    HStack {
                        Text(L10n.version)
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.about)
                }
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}
