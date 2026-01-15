import SwiftUI

struct AddTokenView: View {
    @StateObject private var viewModel: AddTokenViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    init(onTokenAdded: @escaping (Token) -> Void) {
        _viewModel = StateObject(wrappedValue: AddTokenViewModel(onTokenAdded: onTokenAdded))
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Input Method", selection: $selectedTab) {
                    Text("Scan QR").tag(0)
                    Text("Manual Entry").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    scannerTab
                } else {
                    manualEntryTab
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var scannerTab: some View {
        VStack {
            Text("Position QR code within frame")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()

            QRCodeScannerView(
                onCodeScanned: { code in
                    viewModel.handleScannedCode(code)
                    dismiss()
                },
                onError: { error in
                    viewModel.handleScanError(error)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()
        }
    }

    private var manualEntryTab: some View {
        Form {
            Section(header: Text("Account Information")) {
                TextField("Issuer (e.g., GitHub)", text: $viewModel.issuer)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                TextField("Account (e.g., user@example.com)", text: $viewModel.account)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
            }

            Section(header: Text("Secret Key")) {
                TextField("Secret", text: $viewModel.secret)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .font(.system(.body, design: .monospaced))
            }

            Section(header: Text("Advanced Settings")) {
                Stepper("Digits: \(viewModel.digits)", value: $viewModel.digits, in: 6...8)

                Stepper("Period: \(viewModel.period)s", value: $viewModel.period, in: 15...60, step: 15)

                Picker("Algorithm", selection: $viewModel.algorithm) {
                    ForEach(TOTPAlgorithm.allCases, id: \.self) { algorithm in
                        Text(algorithm.rawValue).tag(algorithm)
                    }
                }
            }

            Section {
                Button(action: {
                    viewModel.addManualToken()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }) {
                    Text("Add Account")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
    }
}
