//
//  OnboardingView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct OnboardingView: View {
    @EnvironmentObject var languageAdapter: LanguageAdapter
    
    private let onSelectNewbie: () -> Void
    private let onSelectExperienced: () -> Void
    
    public init(onSelectNewbie: @escaping () -> Void, onSelectExperienced: @escaping () -> Void) {
        self.onSelectNewbie = onSelectNewbie
        self.onSelectExperienced = onSelectExperienced
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Menu {
                        Button("English") { languageAdapter.update(languageCode: "en") }
                        Button("Bahasa Indonesia") { languageAdapter.update(languageCode: "id") }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text(languageAdapter.currentLanguage == "id" ? "ID" : "EN")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.surface)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Logo Area
                VStack(spacing: 16) {
                    Text("♟")
                        .font(.system(size: 80))
                    Text("Essential Chess")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Master tactics. Unlock your potential.")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Choices Area
                VStack(spacing: 14) {
                    Text("Where do you start?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button(action: onSelectNewbie) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I'm new to chess")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Start from the very beginning")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    Button(action: onSelectExperienced) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I have experience")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Take a 15-puzzle placement test")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(20)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}
