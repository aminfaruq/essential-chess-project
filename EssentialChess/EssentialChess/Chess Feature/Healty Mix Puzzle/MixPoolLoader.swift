//
//  MixPoolLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public enum LoadMixPoolResult {
    case success(MixPool)
    case failure(Error)
}

public protocol MixPoolLoader {
    func load(completion: @escaping (LoadMixPoolResult) -> Void)
}
