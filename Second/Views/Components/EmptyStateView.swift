import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Tap + to add your first account")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
