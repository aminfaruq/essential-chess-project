//
//  PuzzleMixView.swift
//  EssentialChessApp
//
//  Created by App on 11/06/26.
//

import SwiftUI
import EssentialChessUI

public struct PuzzleMixView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                        .padding(.bottom, 16)
                    
                    Text("Puzzle Mix")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Coming Soon")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("Puzzle Mix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
