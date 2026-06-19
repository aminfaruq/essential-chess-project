//
//  LanguageAdapter.swift
//  EssentialChess
//

import Foundation
import Combine

public final class LanguageAdapter: ObservableObject {
    private var store: LanguageStoragePort
    
    @Published public private(set) var currentLanguage: String
    
    public init(store: LanguageStoragePort) {
        self.store = store
        self.currentLanguage = store.languageCode
    }
    
    public func load() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentLanguage = self.store.languageCode
        }
    }
    
    public func update(languageCode: String) {
        guard currentLanguage != languageCode else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.store.languageCode = languageCode
            self.currentLanguage = languageCode
        }
    }
}
