//
//  ThemeStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public protocol ThemeStore {
    typealias RetrievalResult = Swift.Result<ThemeSettings?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>
    
    func retrieve(completion: @escaping (RetrievalResult) -> Void)
    func insert(_ settings: ThemeSettings, completion: @escaping (InsertionResult) -> Void)
}
