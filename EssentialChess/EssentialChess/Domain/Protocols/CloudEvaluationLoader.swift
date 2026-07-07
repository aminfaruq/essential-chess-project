//
//  CloudEvaluationLoader.swift
//  EssentialChess
//

import Foundation

public protocol CloudEvaluationLoader {
    typealias Result = Swift.Result<CloudEvaluation, Error>
    
    func load(fen: String, completion: @escaping (Result) -> Void)
}
