//
//  iCloudExportView.swift
//  Second
//
//  Created by Second Team on 2026-01-17.
//

import SwiftUI

/// iCloud export view for exporting tokens to CSV format
struct iCloudExportView: View {
    @StateObject private var viewModel = iCloudExportViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header icon
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 40)

            // Description
            VStack(spacing: 12) {
                Text(L10n.exportiCloudData)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(L10n.exportDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Token count
            if viewModel.tokenCount > 0 {
                VStack(spacing: 8) {
                    Text(L10n.currentAccountCount)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.tokenCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 24)
            }

            Spacer()

            // Export button
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.exportToCSV()
                }) {
                    HStack {
                        if viewModel.isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }

                        Text(viewModel.isExporting ? L10n.exporting : L10n.exportCSV)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.tokenCount > 0 ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.tokenCount == 0 || viewModel.isExporting)
                .padding(.horizontal, 24)

                if viewModel.tokenCount == 0 {
                    Text(L10n.noAccountsToExport)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(L10n.iCloudDataExport)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.exportSuccessful, isPresented: $viewModel.showingSuccess) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.csvSaved)
        }
        .alert(L10n.exportFailed, isPresented: $viewModel.showingError) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            viewModel.loadTokenCount()
        }
    }
}

/// Share sheet for exporting files
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
