//
//  TokenListView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI

/// Main screen displaying token list with search and add functionality
struct TokenListView: View {
    @StateObject private var viewModel = TokenListViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar with search, settings, and add button
                HStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField(L10n.searchPlaceholder, text: $viewModel.searchText)
                            .textFieldStyle(.plain)

                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Settings button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel(L10n.settings)

                    // Add button
                    Menu {
                        Button(action: {
                            viewModel.addTokenMode = .scan
                            viewModel.showingAddToken = true
                        }) {
                            Label(L10n.scanQRCode, systemImage: "qrcode.viewfinder")
                        }
                        .accessibilityLabel(L10n.scanQRCodeToAdd)

                        Button(action: {
                            viewModel.addTokenMode = .manual
                            viewModel.showingAddToken = true
                        }) {
                            Label(L10n.manualEntry, systemImage: "keyboard")
                        }
                        .accessibilityLabel(L10n.manuallyEnterToAdd)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel(L10n.addNewToken)
                    .accessibilityHint(L10n.chooseMethod)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                // Sync status indicator
                if let syncStatus = viewModel.syncStatusMessage {
                    HStack(spacing: 6) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "checkmark.icloud")
                                .font(.caption)
                                .foregroundColor(Color(.systemGreen))
                        }

                        Text(syncStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                }

                Divider()

                // Content
                ZStack {
                    if viewModel.isLoading {
                        ProgressView(L10n.loading)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        // Error state - use ErrorStateView for missing key scenario
                        if error.contains("iCloud 同步") && error.contains("解密密钥不可用") {
                            ErrorStateView.missingVaultKey
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ErrorStateView(message: error, guidance: L10n.tryAgainOrContactSupport)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else if viewModel.tokens.isEmpty {
                        // Empty state
                        EmptyStateView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.searchText.isEmpty && viewModel.filteredTokens.isEmpty {
                        // Empty search results
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)

                            Text(L10n.noMatchingTokens)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(L10n.trySearchingOther)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Token list
                        List {
                            ForEach(viewModel.filteredTokens) { token in
                                TokenCardView(token: token) {
                                    viewModel.copyCode(for: token)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .contextMenu {
                                        Button(action: {
                                            viewModel.editToken(token)
                                        }) {
                                            Label(L10n.edit, systemImage: "pencil")
                                        }

                                        Button(role: .destructive, action: {
                                            viewModel.requestDeleteToken(token)
                                        }) {
                                            Label(L10n.delete, systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete(perform: viewModel.deleteToken)
                        }
                        .listStyle(.plain)
                    }

                    // Toast notification
                    if let toast = viewModel.toastMessage {
                        VStack {
                            Spacer()
                            Text(toast)
                                .padding()
                                .background(Color(.systemGray))
                                .foregroundColor(Color(.label))
                                .cornerRadius(10)
                                .padding(.bottom, 50)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: viewModel.toastMessage)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddToken) {
                AddTokenView(initialMode: viewModel.addTokenMode) { token in
                    viewModel.addToken(token)
                }
            }
            .sheet(isPresented: $viewModel.showingEditToken) {
                if let token = viewModel.tokenToEdit {
                    EditTokenView(token: token) { updatedToken in
                        viewModel.updateToken(updatedToken)
                    }
                }
            }
            .alert(L10n.confirmDelete, isPresented: $viewModel.showingDeleteConfirmation) {
                Button(L10n.cancel, role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button(L10n.delete, role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                if let token = viewModel.tokenToDelete {
                    Text(L10n.confirmDeleteMessage(issuer: token.issuer, account: token.account))
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}
