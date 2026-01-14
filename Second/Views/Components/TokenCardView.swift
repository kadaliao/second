//
//  TokenCardView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI

/// Individual token card displaying TOTP code and countdown
struct TokenCardView: View {
    let token: Token
    let onCopy: () -> Void
    @State private var totpCode: String = "------"
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer?
    @State private var showCopied: Bool = false

    // 根据 token ID 生成一致的颜色
    private var accentColor: Color {
        let colorSets: [(light: Color, dark: Color)] = [
            // 淡蓝色系 - 浅色模式用浅色，深色模式用深色
            (light: Color(red: 0.93, green: 0.95, blue: 0.98),
             dark: Color(red: 0.15, green: 0.18, blue: 0.22)),
            // 淡绿色系
            (light: Color(red: 0.93, green: 0.98, blue: 0.95),
             dark: Color(red: 0.15, green: 0.20, blue: 0.17)),
            // 淡橙色系
            (light: Color(red: 0.98, green: 0.95, blue: 0.93),
             dark: Color(red: 0.22, green: 0.18, blue: 0.15)),
            // 淡紫色系
            (light: Color(red: 0.96, green: 0.93, blue: 0.98),
             dark: Color(red: 0.20, green: 0.15, blue: 0.22)),
            // 淡粉色系
            (light: Color(red: 0.98, green: 0.93, blue: 0.95),
             dark: Color(red: 0.22, green: 0.15, blue: 0.18)),
            // 淡青色系
            (light: Color(red: 0.93, green: 0.96, blue: 0.96),
             dark: Color(red: 0.15, green: 0.20, blue: 0.20)),
        ]

        // 使用 token ID 的哈希值来选择颜色
        let hash = abs(token.id.hashValue)
        let colorSet = colorSets[hash % colorSets.count]

        // 返回适配颜色（iOS 会自动根据当前外观模式选择）
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(colorSet.dark)
            } else {
                return UIColor(colorSet.light)
            }
        })
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(token.issuer)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityLabel("发行方: \(token.issuer)")

                Text(token.account)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("账户: \(token.account)")

                // 验证码显示区域 - 支持切换到"已复制"
                ZStack {
                    Text(TOTPGenerator.format(code: totpCode))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .opacity(showCopied ? 0 : 1)

                    Text("已复制")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(.systemGreen))
                        .opacity(showCopied ? 1 : 0)
                }
                .padding(.top, 4)
                .accessibilityLabel("验证码: \(totpCode)")
                .accessibilityHint("双击以复制到剪贴板")
                .animation(.easeInOut(duration: 0.2), value: showCopied)
            }

            Spacer()

            CountdownTimerView(timeRemaining: timeRemaining, period: token.period)
                .accessibilityLabel("剩余时间: \(timeRemaining) 秒")
        }
        .padding()
        .background(accentColor)
        .cornerRadius(12)
        .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .onTapGesture {
            handleCopy()
        }
        .onAppear {
            updateCode()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func handleCopy() {
        onCopy()

        // 显示"已复制"反馈
        withAnimation {
            showCopied = true
        }

        // 1秒后恢复显示验证码
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showCopied = false
            }
        }
    }

    private func updateCode() {
        if let code = TOTPGenerator.generate(token: token) {
            totpCode = code
            timeRemaining = TOTPGenerator.timeRemaining(for: token)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateCode()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
