//
//  OpeningDashboardViewModel.swift
//  EssentialChessUI
//

import Foundation
import EssentialChess
import Combine

public final class OpeningDashboardViewModel: ObservableObject {
    @Published public var categories: [OpeningCategoryPreview] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let store: RepertoireStore
    
    public init(store: RepertoireStore) {
        self.store = store
    }
    
    public func loadCategories() {
        guard categories.isEmpty else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            self.categories = try self.store.fetchOpeningCategories()
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
