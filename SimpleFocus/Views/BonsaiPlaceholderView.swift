//
//  BonsaiPlaceholderView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct BonsaiPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .padding(.bottom, 8)

            Text("专注盆景开发中")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Text("即将为你带来更沉浸的成长激励体验。\n感谢耐心等待。")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    BonsaiPlaceholderView()
}
