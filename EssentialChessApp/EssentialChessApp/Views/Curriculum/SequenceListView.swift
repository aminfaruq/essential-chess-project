//
//  SequenceListView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

struct SequenceListView: View {
    @ObservedObject var vm: PuzzleBoardViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                List {
                    ForEach(0..<vm.puzzles.count, id: \.self) { i in
                        let unlocked  = i < vm.unlockedCount
                        let completed = vm.isCompleted(vm.puzzles[i])
                        let isCurrent = i == vm.currentActiveIndex
                        
                        Button {
                            vm.jumpTo(index: i)
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                // Status icon
                                Group {
                                    if isCurrent {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                    } else if completed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                    } else if unlocked {
                                        Image(systemName: "circle")
                                            .foregroundColor(AppColors.textSecondary)
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(AppColors.locked)
                                    }
                                }
                                .frame(width: 20)
                                
                                Text("Puzzle \(i + 1)")
                                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                                    .foregroundColor(unlocked ? AppColors.textPrimary : AppColors.locked)
                                
                                Spacer()
                                
                                if let rating = unlocked ? vm.puzzles[i].rating : nil {
                                    Label("\(rating)", systemImage: "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.gold.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(!unlocked)
                        .listRowBackground(
                            isCurrent ? AppColors.accent.opacity(0.08) : AppColors.surface
                        )
                        .hoverEffect(.highlight)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Puzzle Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(AppColors.accent)
                        .hoverEffect(.highlight)
                }
            }
        }
    }
}
