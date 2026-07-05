//
//  ECOLoader.swift
//  EssentialChess
//

import Foundation

public protocol ECOLoader {
    typealias Result = Swift.Result<[String: ECOOpening], Swift.Error>

    func load(completion: @escaping (Result) -> Void)
}
