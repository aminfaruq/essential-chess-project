//
//  PuzzleStreakView.swift
//  EssentialChessApp
//

import SwiftUI
import EssentialChessUI

public struct PuzzleStreakView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Puzzle Streak")
                .font(.title)
                .bold()
                .padding(.top, 8)
            Text("Coming Soon")
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}
