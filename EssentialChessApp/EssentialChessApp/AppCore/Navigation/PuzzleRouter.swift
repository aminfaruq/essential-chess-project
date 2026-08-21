//
//  PuzzleRouter.swift
//  EssentialChessApp
//
//  Created by App on 21/08/26.
//

import SwiftUI
import Combine

@MainActor
public final class PuzzleRouter: ObservableObject {
    @Published public var path = NavigationPath()
    
    public init() {}
    
    public func navigate(to route: PuzzleRoute) {
        path.append(route)
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    public func popToRoot() {
        path = NavigationPath()
    }
}
