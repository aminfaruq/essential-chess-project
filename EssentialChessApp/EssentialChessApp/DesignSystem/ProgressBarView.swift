//
//  ProgressBarView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI

public struct ProgressBarView: View {
    public let progress: Double  // 0.0 – 1.0
    public var height: CGFloat = 4
    public var trackColor: Color = Color.white.opacity(0.12)
    public var fillColor: Color = AppColors.accent
    
    public init(progress: Double, height: CGFloat = 4, trackColor: Color = Color.white.opacity(0.12), fillColor: Color = AppColors.accent) {
        self.progress = progress
        self.height = height
        self.trackColor = trackColor
        self.fillColor = fillColor
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule()
                    .fill(fillColor)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}
