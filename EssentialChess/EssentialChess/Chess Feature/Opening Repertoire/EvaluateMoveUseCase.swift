//
//  EvaluateMoveUseCase.swift
//  EssentialChess
//

import Foundation

public enum EvaluationResult: Equatable {
    /// The user played the correct main line move. The computer responds with `computerResponse`.
    case correct(computerResponse: RepertoireNode?)
    
    /// The user played a valid move from the database, but it is not currently set as the main line.
    case alternativeLine(RepertoireNode)
    
    /// The user played a move that does not exist in the local database. Fetches punishment from Lichess Cloud.
    case blunder(punishmentMoveUci: String?)
}

public protocol EvaluateMoveUseCase {
    /// Evaluates the user's move against the local database or cloud fallback.
    /// - Parameters:
    ///   - userMoveUci: The UCI string of the user's move (e.g. "e2e4").
    ///   - currentFen: The FEN of the board *before* the user made the move.
    ///   - resultingFen: The FEN of the board *after* the user made the move (needed for Cloud Eval).
    ///   - completion: Callback with the evaluation result.
    func evaluate(userMoveUci: String, currentFen: String, resultingFen: String, completion: @escaping (Result<EvaluationResult, Error>) -> Void)
}

public final class DefaultEvaluateMoveUseCase: EvaluateMoveUseCase {
    private let store: RepertoireStore
    private let cloudLoader: CloudEvaluationLoader
    
    public enum Error: Swift.Error {
        case storeError
        case cloudError
    }
    
    public init(store: RepertoireStore, cloudLoader: CloudEvaluationLoader) {
        self.store = store
        self.cloudLoader = cloudLoader
    }
    
    public func evaluate(userMoveUci: String, currentFen: String, resultingFen: String, completion: @escaping (Result<EvaluationResult, Swift.Error>) -> Void) {
        do {
            let children = try store.children(for: currentFen)
            
            if let matchedNode = children.first(where: { $0.uciMove == userMoveUci }) {
                if matchedNode.isMainLine {
                    let responses = try store.children(for: matchedNode.fen)
                    let computerResponse = responses.first(where: { $0.isMainLine }) ?? responses.first
                    completion(.success(.correct(computerResponse: computerResponse)))
                } else {
                    completion(.success(.alternativeLine(matchedNode)))
                }
            } else {
                cloudLoader.load(fen: resultingFen) { result in
                    switch result {
                    case let .success(eval):
                        let firstMove = eval.pvs.first?.moves.components(separatedBy: " ").first
                        completion(.success(.blunder(punishmentMoveUci: firstMove)))
                    case .failure:
                        completion(.failure(Error.cloudError))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
