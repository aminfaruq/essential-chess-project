//
//  PuzzleStormView.swift
//  EssentialChessApp
//

import SwiftUI
import EssentialChessUI

public struct PuzzleStormView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            Text("Puzzle Storm")
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
