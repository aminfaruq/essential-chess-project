//
//  MainNavigationViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//
import EssentialChess
import Combine

public final class MainNavigationViewModel: ObservableObject {
    @Published public var selectedTab: AppTab
    
    private var tabStorage: TabStoragePort
    private var cancellables = Set<AnyCancellable>()
    
    public init(tabStorage: TabStoragePort) {
        self.tabStorage = tabStorage
        // Load initial state from storage
        self.selectedTab = tabStorage.savedTab
        
        // Automatically save to storage whenever selectedTab changes
        $selectedTab
            .dropFirst() // Prevent saving the initial value upon creation
            .sink { [weak self] newTab in
                self?.tabStorage.savedTab = newTab
            }
            .store(in: &cancellables)
    }
    
    public func resetToCurriculum() {
        self.selectedTab = .curriculum
    }
}
