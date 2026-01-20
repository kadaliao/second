//
//  AddTokenView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI
import UIKit

/// Modal view for adding new tokens (QR scan or manual entry)
struct AddTokenView: View {
    @StateObject private var viewModel = AddTokenViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingManualInput: Bool
    @State private var scannedCode: String?
    @State private var cameraPermissionDenied = false
#if DEBUG
    private let screenshotMode = ProcessInfo.processInfo.environment["SCREENSHOT_MODE"]

    private var isScreenshotMode: Bool {
        screenshotMode != nil
    }
#else
    private var isScreenshotMode: Bool {
        false
    }
#endif

    var onTokenAdded: ((Token) -> Void)?

    init(initialMode: AddTokenMode = .scan, onTokenAdded: ((Token) -> Void)? = nil) {
        _showingManualInput = State(initialValue: initialMode == .manual)
        self.onTokenAdded = onTokenAdded
    }

    var body: some View {
        ZStack {
            if showingManualInput {
                // 手动输入界面
                NavigationView {
                    Form {
                        Section(header: Text(L10n.manualEntry)) {
                            TextField(L10n.issuerPlaceholder, text: $viewModel.issuer)
                                .autocapitalization(.words)

                            TextField(L10n.accountPlaceholder, text: $viewModel.account)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)

                            TextField(L10n.secretPlaceholder, text: $viewModel.secret)
                                .autocapitalization(.allCharacters)
                                .font(.system(.body, design: .monospaced))
                        }

                        if let error = viewModel.errorMessage {
                            Section {
                                Text(error)
                                    .foregroundColor(Color(.systemRed))
                                    .font(.caption)
                            }
                        }

                        Section {
                            Button(L10n.add) {
                                viewModel.addManually()
                            }
                            .disabled(viewModel.issuer.isEmpty || viewModel.account.isEmpty || viewModel.secret.isEmpty)
                        }
                    }
                    .navigationTitle(L10n.addAuthenticator)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.cancel) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button(L10n.scan) {
                                showingManualInput = false
                            }
                        }
                    }
                }
            } else {
                // 扫描界面
                ZStack {
                    if isScreenshotMode {
                        ScreenshotScannerView()
                    } else if cameraPermissionDenied {
                        // 相机权限被拒绝时显示的界面
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(.systemGray))

                            Text(L10n.cameraPermissionRequired)
                                .font(.headline)

                            Text(L10n.allowCameraAccess)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(L10n.openSettings) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else {
                        QRCodeScannerView(scannedCode: $scannedCode)
                    }

                    VStack {
                        // 顶部导航栏
                        HStack {
                            Spacer()

                            Text(L10n.scanQRCode)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.bottom, 20)
                        .background(Color.black.opacity(0.3))

                        Spacer()

                        // 底部提示
                        VStack(spacing: 16) {
                            Text(L10n.alignQRCode)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.bottom, 60)
                    }

                    // 关闭按钮（左上角）
                    VStack {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .padding()

                            Spacer()
                        }
                        Spacer()
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onChange(of: scannedCode) { newValue in
            if let code = newValue {
                viewModel.parseQRCode(code)
                scannedCode = nil
            }
        }
        .onChange(of: showingManualInput) { isManual in
            guard !isManual else { return }
            guard !isScreenshotMode else {
                cameraPermissionDenied = false
                return
            }
            viewModel.checkCameraPermission { granted in
                cameraPermissionDenied = !granted
            }
        }
        .onAppear {
            viewModel.onTokenAdded = { token in
                onTokenAdded?(token)
                presentationMode.wrappedValue.dismiss()
            }

            // 检查相机权限
            if isScreenshotMode || showingManualInput {
                cameraPermissionDenied = false
            } else {
                viewModel.checkCameraPermission { granted in
                    cameraPermissionDenied = !granted
                }
            }
        }
    }
}

private struct ScreenshotScannerView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height) * 0.65

            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: size, height: size)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: size * 0.35, weight: .light))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
