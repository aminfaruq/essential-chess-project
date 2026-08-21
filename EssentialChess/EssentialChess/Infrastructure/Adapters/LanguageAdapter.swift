//
//  LanguageAdapter.swift
//  EssentialChess
//

import Foundation
import Combine

@MainActor
public final class LanguageAdapter: ObservableObject {
    private var store: LanguageStore
    
    @Published public private(set) var currentLanguage: String
    
    public init(store: LanguageStore) {
        self.store = store
        self.currentLanguage = store.languageCode
    }
    
    public func load() {
        currentLanguage = store.languageCode
    }
    
    public func update(languageCode: String) {
        guard currentLanguage != languageCode else { return }
        
        store.languageCode = languageCode
        currentLanguage = languageCode
    }
}
