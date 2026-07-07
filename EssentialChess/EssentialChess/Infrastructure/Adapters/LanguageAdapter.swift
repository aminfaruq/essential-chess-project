//
//  LanguageAdapter.swift
//  EssentialChess
//

import Foundation
import Combine

public final class LanguageAdapter: ObservableObject {
    private var store: LanguageStore
    
    @Published public private(set) var currentLanguage: String
    
    public init(store: LanguageStore) {
        self.store = store
        self.currentLanguage = store.languageCode
    }
    
    public func load() {
        DispatchQueue.main.async {
            self.currentLanguage = self.store.languageCode
        }
    }
    
    public func update(languageCode: String) {
        guard currentLanguage != languageCode else { return }
        
        DispatchQueue.main.async {
            self.store.languageCode = languageCode
            self.currentLanguage = languageCode
        }
    }
}
