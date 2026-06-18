//
//  EnvironmentConfig.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 18/06/26.
//

import Foundation

public struct EnvironmentConfig {
    public static var currentMode: String {
        #if DEBUG
        return "Development Mode (Simulator)"
        #elseif STAGING
        return "TestFlight Mode (Beta)"
        #else
        return "Production Mode (App Store)"
        #endif
    }
    
    public static var revenueCatAPIKey: String {
        #if DEBUG || STAGING
        return "appl_beta_key_disini"
        #else
        return "appl_production_key_disini"
        #endif
    }
}
