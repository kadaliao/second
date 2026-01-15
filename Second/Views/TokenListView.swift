import SwiftUI

struct TokenListView: View {
    @StateObject private var viewModel = TokenListViewModel()
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.vault.tokens.isEmpty {
                    EmptyStateView()
                } else {
                    tokenList
                }

                if showToast {
                    toastView
                }
            }
            .navigationTitle("Second")
            .searchable(text: $viewModel.searchText, prompt: "Search accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showAddToken = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddToken) {
                AddTokenView(onTokenAdded: { token in
                    viewModel.addToken(token)
                    showToastMessage("Account added")
                })
            }
            .task {
                await viewModel.loadVault()
            }
        }
    }

    private var tokenList: some View {
        List {
            ForEach(viewModel.filteredTokens) { token in
                TokenCardView(
                    token: token,
                    code: viewModel.currentCodes[token.id] ?? "------",
                    timeRemaining: viewModel.timeRemaining,
                    onTap: {
                        if let code = viewModel.currentCodes[token.id] {
                            viewModel.copyToClipboard(code: code)
                            showToastMessage("Copied to clipboard")
                        }
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .onDelete(perform: deleteTokens)
        }
        .listStyle(.plain)
    }

    private var toastView: some View {
        VStack {
            Spacer()
            Text(toastMessage)
                .padding()
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: showToast)
    }

    private func deleteTokens(at offsets: IndexSet) {
        for index in offsets {
            let token = viewModel.filteredTokens[index]
            viewModel.deleteToken(id: token.id)
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}
