//
//  EmptyStateView.swift
//  Second
//
//  Created by Second Team on 2026-01-15.
//

import SwiftUI

/// Empty state view shown when no tokens exist
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(L10n.noAuthenticators)
                .font(.title2)
                .fontWeight(.semibold)

            Text(L10n.tapPlusToAdd)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.noAuthenticatorsAccessibility)
    }
}
