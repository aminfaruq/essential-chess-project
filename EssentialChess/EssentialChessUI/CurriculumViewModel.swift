//
//  CurriculumViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class CurriculumViewModel: ObservableObject {
    @Published public private(set) var sections: [EloSection] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    
    // We inject closures that return Publishers to keep it highly decoupled
    private let curriculumPublisher: () -> AnyPublisher<Curriculum, Error>
    private let mixPoolPublisher: () -> AnyPublisher<MixPool, Error>
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        curriculumPublisher: @escaping () -> AnyPublisher<Curriculum, Error>,
        mixPoolPublisher: @escaping () -> AnyPublisher<MixPool, Error>
    ) {
        self.curriculumPublisher = curriculumPublisher
        self.mixPoolPublisher = mixPoolPublisher
    }
    
    public func load() {
        isLoading = true
        errorMessage = nil
        
        // Fetch both data sources concurrently
        Publishers.Zip(curriculumPublisher(), mixPoolPublisher())
        // Ensure state changes happen on the main thread for SwiftUI
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case let .failure(error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] curriculum, mixPool in
                    guard let self = self else { return }
                    self.sections = curriculum.sections
                    // Note: We can assign mixPool data to another @Published property if needed by the UI later
                }
            )
            .store(in: &cancellables)
    }
}
