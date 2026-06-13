//
//  MainTabView.swift
//  EssentialChessApp
//
//  Created by App on 11/06/26.
//

import SwiftUI
import EssentialChessUI

enum AppTab: Hashable {
    case curriculum
    case puzzleMix
    case settings
}

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .curriculum
    @State private var curriculumScrollToTopTrigger: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab && newTab == .curriculum {
                    curriculumScrollToTopTrigger += 1
                }
                selectedTab = newTab
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
    }
}
