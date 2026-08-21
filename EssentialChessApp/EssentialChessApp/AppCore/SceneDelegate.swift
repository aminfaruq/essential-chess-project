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

    private var _composer: AppComposer?
    var composer: AppComposer {
        get {
            if let c = _composer {
                return c
            }
            let newComposer = AppComposer()
            _composer = newComposer
            return newComposer
        }
        set {
            _composer = newValue
        }
    }
    
    override init() {
        super.init()
    }
    
    convenience init(composer: AppComposer) {
        self.init()
        self._composer = composer
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

