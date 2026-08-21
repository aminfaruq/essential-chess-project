//
//  CurriculumRouter.swift
//  EssentialChessApp
//
//  Created by App on 21/08/26.
//

import SwiftUI
import EssentialChessUI

@MainActor
public final class CurriculumRouter: ObservableObject {
    @Published public var path = NavigationPath()
    @Published public var presentedExamCategory: CategoryUIModel?
    
    public init() {}
    
    public func navigate(to route: CurriculumRoute) {
        path.append(route)
    }
    
    public func presentExam(_ category: CategoryUIModel) {
        presentedExamCategory = category
    }
    
    public func dismissExam() {
        presentedExamCategory = nil
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    public func popToRoot() {
        path = NavigationPath()
        presentedExamCategory = nil
    }
}
