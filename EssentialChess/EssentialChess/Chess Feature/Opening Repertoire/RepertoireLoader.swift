//
//  RepertoireLoader.swift
//  EssentialChess
//

import Foundation

public protocol RepertoireLoader {
    typealias Result = Swift.Result<[RepertoireNode], Error>
    
    func load(completion: @escaping (Result) -> Void)
}
