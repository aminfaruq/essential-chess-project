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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let composer = AppComposer()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        let rootViewController = UIHostingController(
            rootView: AppRootView(composer: composer)
        )
        
        window.rootViewController = rootViewController
        self.window = window
        window.makeKeyAndVisible()
    }
}

