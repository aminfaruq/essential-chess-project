//
//  MainTabView.swift
//  EssentialChessApp
//
//  Created by App on 11/06/26.
//

import SwiftUI
import EssentialChess
import EssentialChessUI

public struct MainTabView: View {
    @ObservedObject var navigationViewModel: MainNavigationViewModel
    @State private var curriculumScrollToTopTrigger: Int = 0
    
    public init(navigationViewModel: MainNavigationViewModel) {
        self.navigationViewModel = navigationViewModel
    }
    
    public var body: some View {
        TabView(selection: Binding(
            get: { navigationViewModel.selectedTab },
            set: { newTab in
                if newTab == navigationViewModel.selectedTab && newTab == .curriculum {
                    curriculumScrollToTopTrigger += 1
                }
                navigationViewModel.selectedTab = newTab
            }
        )) {
            CurriculumView(scrollToTopTrigger: $curriculumScrollToTopTrigger)
                .tabItem {
                    Label("Curriculum", systemImage: "book.fill")
                }
                .tag(AppTab.curriculum)
            
            PuzzleMixView()
                .tabItem {
                    Label("Puzzle Mix", systemImage: "puzzlepiece.extension.fill")
                }
                .tag(AppTab.puzzleMix)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.accent)
        // Adjust the TabBar appearance to match the dark theme
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColors.surface)
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkToPuzzleMix"))) { _ in
            navigationViewModel.selectedTab = .puzzleMix
        }
    }
}
