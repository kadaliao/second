//
//  EditTokenView.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import SwiftUI

/// Modal view for editing existing tokens
struct EditTokenView: View {
    @StateObject private var viewModel: EditTokenViewModel
    @Environment(\.presentationMode) var presentationMode

    /// Initialize with token to edit and save callback
    init(token: Token, onSave: @escaping (Token) -> Void) {
        _viewModel = StateObject(wrappedValue: EditTokenViewModel(token: token, onSave: { updatedToken in
            onSave(updatedToken)
        }))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L10n.editAuthenticator)) {
                    TextField(L10n.issuerPlaceholder, text: $viewModel.issuer)
                        .autocapitalization(.words)

                    TextField(L10n.accountPlaceholder, text: $viewModel.account)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(Color(.systemRed))
                            .font(.caption)
                    }
                }

                if viewModel.hasChanges {
                    Section {
                        Text(L10n.changesWillSync)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(L10n.save) {
                        viewModel.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!viewModel.isValid)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L10n.editAuthenticator)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        viewModel.cancel()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct EditTokenView_Previews: PreviewProvider {
    static var previews: some View {
        EditTokenView(token: Token(
            issuer: "GitHub",
            account: "user@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            digits: 6,
            period: 30,
            algorithm: .sha1
        )) { _ in
            // Preview callback›
        }
    }
}
#endif
