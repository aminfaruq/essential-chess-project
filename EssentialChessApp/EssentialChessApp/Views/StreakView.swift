//
//  StreakView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 14/06/26.
//

import SwiftUI
import EssentialChessUI

public struct StreakView: View {
    @EnvironmentObject var streakViewModel: StreakViewModel
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(streakViewModel.isStreakActiveToday ? Color.orange : AppColors.textSecondary.opacity(0.5))
            
            Text("\(streakViewModel.streakCount)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(streakViewModel.isStreakActiveToday ? Color.orange : AppColors.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .cornerRadius(12)
    }
}
