import SwiftUI

struct CountdownTimerView: View {
    let timeRemaining: Int
    let period: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.3)
                .foregroundColor(timeRemaining <= 5 ? .red : .blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(period))
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundColor(timeRemaining <= 5 ? .red : .blue)
                .rotationEffect(.degrees(-90))

            Text("\(timeRemaining)")
                .font(.caption)
                .bold()
        }
        .frame(width: 40, height: 40)
    }
}
