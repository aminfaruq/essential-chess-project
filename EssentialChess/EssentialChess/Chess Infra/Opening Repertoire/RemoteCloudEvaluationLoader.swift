//
//  RemoteCloudEvaluationLoader.swift
//  EssentialChess
//

import Foundation

public final class RemoteCloudEvaluationLoader: CloudEvaluationLoader {
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public func load(fen: String, completion: @escaping (CloudEvaluationLoader.Result) -> Void) {
        guard let encodedFen = fen.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lichess.org/api/cloud-eval?fen=\(encodedFen)&multiPv=3&variant=standard") else {
            return
        }
        
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                do {
                    let evaluation = try CloudEvaluationMapper.map(data, response: response)
                    completion(.success(evaluation))
                } catch {
                    completion(.failure(Error.invalidData))
                }
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
