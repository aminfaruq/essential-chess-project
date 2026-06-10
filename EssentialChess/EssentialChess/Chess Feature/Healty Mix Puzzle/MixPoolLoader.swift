//
//  MixPoolLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public protocol MixPoolLoader {
    typealias Result = Swift.Result<MixPool, Swift.Error>
    
    func load(completion: @escaping (Result) -> Void)
}
