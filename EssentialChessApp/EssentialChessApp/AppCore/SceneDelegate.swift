//
//  SceneDelegate.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 10/06/26.
//

import UIKit
import EssentialChess
import EssentialChessUI
import SwiftUI

@MainActor
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private(set) lazy var composer = AppComposer()
    
    convenience init(composer: AppComposer) {
        self.init()
        self.composer = composer
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        #if DEBUG
        if NSClassFromString("XCTestCase") != nil {
            return
        }
        #endif
        
        let window = UIWindow(windowScene: windowScene)
        configureWindow(window)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func configureWindow(_ window: UIWindow) {
        let rootViewController = UIHostingController(
            rootView: AppRootView(composer: composer)
        )
        window.rootViewController = rootViewController
    }
}

