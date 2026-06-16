//
//  RootView.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct RootView: View {
    @EnvironmentObject var composer: AppComposer
    
    @State private var onboardingComplete: Bool = false
    
    // We only need the state of this ViewModel now.
    // When it's not nil, the sheet will appear.
    @State private var placementViewModel: OnboardingViewModel?
    
    public init() {}
    
    public var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(
                    onSelectNewbie: {
                        composer.container.progressAdapter.update { progress in
                            composer.navigationVM.resetToCurriculum()
                            progress.hiddenRating = 500.0
                            progress.actualRating = nil
                            progress.onboardingComplete = true
                            progress.completedPuzzleIDs = []
                            progress.passedExamIDs = []
                            progress.examFailureTimes = [:]
                        }
                    },
                    onSelectExperienced: {
                        composer.viewFactory.fetchPlacementViewModel(
                            onFinishedTest: { finalRating in
                                composer.container.progressAdapter.update { progress in
                                    progress.hiddenRating = finalRating
                                    progress.actualRating = nil
                                    progress.onboardingComplete = true
                                    progress.completedPuzzleIDs = []
                                    progress.passedExamIDs = []
                                    progress.examFailureTimes = [:]
                                }
                                composer.navigationVM.resetToCurriculum()
                                // Close the sheet by changing it back to nil
                                self.placementViewModel = nil
                            },
                            onReady: { viewModel in
                                // Trigger fullScreenCover to appear once the puzzle data is ready
                                self.placementViewModel = viewModel
                            }
                        )
                    }
                )
            } else {
                MainTabView(navigationViewModel: composer.navigationVM)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onReceive(composer.container.progressAdapter.publisher()) { progress in
            self.onboardingComplete = progress.onboardingComplete
        }
        .fullScreenCover(item: $placementViewModel) { viewModel in
            ZStack {
                AppColors.background.ignoresSafeArea()
                PlacementTestView(viewModel: viewModel)
            }
        }
    }
}
