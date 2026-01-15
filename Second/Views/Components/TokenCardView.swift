import SwiftUI

struct TokenCardView: View {
    let token: Token
    let code: String
    let timeRemaining: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.issuer)
                        .font(.headline)
                    Text(token.account)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCode(code))
                        .font(.system(.title2, design: .monospaced))
                        .bold()
                }

                Spacer()

                CountdownTimerView(timeRemaining: timeRemaining, period: token.period)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatCode(_ code: String) -> String {
        let mid = code.index(code.startIndex, offsetBy: 3)
        return "\(code[..<mid]) \(code[mid...])"
    }
}
