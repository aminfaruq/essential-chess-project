//
//  ThemeAdapter.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 13/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class ThemeAdapter: ObservableObject {
    
    private let store: ThemeStore
    private let subject: CurrentValueSubject<ThemeSettings, Never>
    
    // For direct SwiftUI usage if injected as an EnvironmentObject
    @Published public private(set) var currentTheme: ThemeSettings
    
    public init(store: ThemeStore) {
        self.store = store
        
        // Initialize with default theme settings to prevent crashes
        let defaultSettings = ThemeSettings(boardTheme: .brown, pieceTheme: "default")
        self.subject = CurrentValueSubject<ThemeSettings, Never>(defaultSettings)
        self.currentTheme = defaultSettings
    }
    
    // MARK: - Inputs
    
    public func load(completion: @escaping () -> Void) {
        store.retrieve { [weak self] result in
            DispatchQueue.main.async {
                if let settings = (try? result.get()) ?? nil {
                    self?.subject.send(settings)
                    self?.currentTheme = settings
                }
                completion()
            }
        }
    }
    
    public func update(_ modifier: (inout ThemeSettings) -> Void) {
        var current = subject.value
        modifier(&current)
        
        subject.send(current)
        self.currentTheme = current // Triggers SwiftUI updates
        
        // Save to UserDefaults in the background
        store.insert(current) { _ in }
    }
    
    // MARK: - Outputs
    
    public func publisher() -> AnyPublisher<ThemeSettings, Never> {
        return subject.eraseToAnyPublisher()
    }
}
