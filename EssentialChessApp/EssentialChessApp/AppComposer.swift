//
//  AppComposer.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import SwiftUI
import Combine
import EssentialChess
import EssentialChessUI

public final class AppComposer: ObservableObject {
    @Published public private(set) var isReady: Bool = false
    
    /// ViewModels
    public let curriculumVM: CurriculumViewModel
    public let navigationVM: MainNavigationViewModel
    public let streakVM: StreakViewModel
    public let settingsVM: SettingsViewModel
    
    /// Core Components
    public let container: DependencyContainer
    public let viewFactory: ViewFactory

    public init() {
        // Initialize Core Components
        self.container = DependencyContainer()
        self.viewFactory = ViewFactory(container: container)
        
        let adapter = container.progressAdapter
        let validCurrLoader = container.curriculumLoader
        let validMixLoader = container.mixPoolLoader
        
        // Initialize ViewModels
        self.curriculumVM = CurriculumViewModel(
            curriculumPublisher: {
                if let loader = validCurrLoader {
                    return loader.publisher()
                }
                return Fail(error: FileCurriculumLoader.Error.invalidData).eraseToAnyPublisher()
            },
            mixPoolPublisher: {
                if let loader = validMixLoader {
                    return loader.publisher()
                }
                return Fail(error: FileMixPoolLoader.Error.invalidData).eraseToAnyPublisher()
            },
            progressPublisher: { [adapter] in adapter.publisher() }
        )
        
        self.streakVM = StreakViewModel(progressPublisher: adapter.publisher())
        
        let tabAdapter = UserDefaultsTabAdapter()
        self.navigationVM = MainNavigationViewModel(tabStorage: tabAdapter)
        
        self.settingsVM = SettingsViewModel(
            notificationStorage: container.notificationStorage,
            notificationScheduler: container.notificationScheduler
        )
    }
    
    public func start() {
        container.curriculumLoader?.load { [weak self] result in
            if case let .success(curriculum) = result {
                self?.viewFactory.cache(curriculum: curriculum)
            }
        }
        
        container.progressAdapter.load { [weak self] in
            DispatchQueue.main.async {
                self?.isReady = true
                self?.curriculumVM.load()
            }
        }
        
        container.themeAdapter.load { }
    }
}


