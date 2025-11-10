//
//  LanguageSelectionView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-08.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.themePalette) private var theme

    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    languageManager.selection = option
                } label: {
                    HStack {
                        Text(languageManager.displayName(for: option))
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        if languageManager.selection == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(theme.surfaceElevated)
        }
        .scrollContentBackground(.hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(languageManager.localized("语言"))
    }
}
