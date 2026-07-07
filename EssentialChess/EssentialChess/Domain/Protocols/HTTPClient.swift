//
//  HTTPClient.swift
//  EssentialChess
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, headers: [String: String]?, completion: @escaping (Result) -> Void)
}

public extension HTTPClient {
    func get(from url: URL, completion: @escaping (Result) -> Void) {
        get(from: url, headers: nil, completion: completion)
    }
}
