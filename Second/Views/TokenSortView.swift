//
//  TokenSortView.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import SwiftUI

/// Token sorting view with drag and drop support
struct TokenSortView: View {
    @StateObject private var viewModel = TokenListViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.tokens.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text(L10n.noAccounts)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(L10n.sortAfterAdding)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.tokens) { token in
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(token.issuer)
                                    .font(.headline)

                                Text(token.account)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .onMove { indices, newOffset in
                        viewModel.moveToken(from: indices, to: newOffset)
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
            }
        }
        .navigationTitle(L10n.sortAccounts)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.done) {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
