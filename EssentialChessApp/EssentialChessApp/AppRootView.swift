//
//  AppRootView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChessUI

public struct AppRootView: View {
    @StateObject private var composer: AppComposer
    
    // Inject from SceneDelegate
    public init(composer: AppComposer) {
        _composer = StateObject(wrappedValue: composer)
    }
    
    public var body: some View {
        Group {
            if composer.isReady {
                RootView()
                // Inject a pure ViewModel into the SwiftUI environment
                    .environmentObject(composer)
                    .environmentObject(composer.curriculumVM)
                    .environmentObject(composer.themeAdapter)
                    .environmentObject(composer.streakVM)
                    .preferredColorScheme(.dark)
            } else {
                // Splash Screen / Loading State
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppColors.accent)
                    Text("Loading chess board...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background.ignoresSafeArea())
                .onAppear {
                    composer.start()
                }
            }
        }
    }
}
