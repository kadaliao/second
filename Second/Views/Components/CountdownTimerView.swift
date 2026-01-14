//
//  CountdownTimerView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI

/// Circular countdown timer component
struct CountdownTimerView: View {
    let timeRemaining: Int
    let period: Int

    private var progress: Double {
        Double(timeRemaining) / Double(period)
    }

    private var timerColor: Color {
        timeRemaining <= 5 ? Color(.systemRed) : Color(.systemBlue)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.3)
                .foregroundColor(timerColor)

            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundColor(timerColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)

            // Time text
            Text("\(timeRemaining)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(timerColor)
        }
        .frame(width: 32, height: 32)
    }
}
