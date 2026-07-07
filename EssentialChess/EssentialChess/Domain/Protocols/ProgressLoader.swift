//
//  ProgressLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public protocol ProgressLoader {
    typealias RetrievalResult = Swift.Result<UserProgress?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>
    
    func retrieve(completion: @escaping (RetrievalResult) -> Void)
    func insert(_ progress: UserProgress, completion: @escaping (InsertionResult) -> Void)
}
