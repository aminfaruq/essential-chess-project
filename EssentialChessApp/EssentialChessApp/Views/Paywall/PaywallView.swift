//
//  PaywallView.swift
//  EssentialChessApp
//
//  Created by App on 15/06/26.
//

import SwiftUI
import EssentialChessUI
import EssentialChess

public struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var container: DependencyContainer
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.gold)
                        .padding(.top, 40)
                    
                    Text("Unlock Essential Chess Pro")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Master tactics faster with unlimited puzzles, full curriculum access, and premium themes.")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Endless Puzzle Mix")
                    FeatureRow(icon: "graduationcap.fill", text: "Intermediate & Advanced Curriculum")
                    FeatureRow(icon: "paintbrush.fill", text: "Premium Board & Piece Themes")
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                
                Spacer()
                
                // Pricing Tiers
                VStack(spacing: 16) {
                    Button { purchasePro() } label: {
                        PricingRow(title: "Lifetime (Best Value)", price: "$19.99 / Rp 149.000", isBestValue: true)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    Button { purchasePro() } label: {
                        PricingRow(title: "Yearly", price: "$14.99 / Rp 99.000", isBestValue: false)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    Button { purchasePro() } label: {
                        PricingRow(title: "Monthly", price: "$2.99 / Rp 29.000", isBestValue: false)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }
                .padding(.horizontal, 24)
                
                // Footer
                HStack {
                    Button("Restore Purchases") { purchasePro() }
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Button("Terms & Privacy") { }
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(16)
        }
    }
    
    // MOCK Purchase Logic until RevenueCat is integrated
    private func purchasePro() {
        container.progressAdapter.update { progress in
            progress.unlockedFeatures.insert(.openingStudy)
        }
        dismiss()
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.gold)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

private struct PricingRow: View {
    let title: String
    let price: String
    let isBestValue: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: isBestValue ? .bold : .medium))
                .foregroundColor(isBestValue ? AppColors.gold : AppColors.textPrimary)
            
            Spacer()
            
            Text(price)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isBestValue ? AppColors.gold : Color.clear, lineWidth: 2)
        )
    }
}
