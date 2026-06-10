//
//  FileMixPoolLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//
import Foundation

public final class FileMixPoolLoader {
    private let url: URL
    private let reader: FileReaderLoader
    
    public enum Error: Swift.Error {
        case readError
        case invalidData
    }
    
    public typealias Result = Swift.Result<MixPool, Error>
    
    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        reader.get(from: url, completion: { result in
            switch result {
            case let .success(data):
                completion(MixPoolMapper.map(data))
            default:
                completion(.failure(.readError))
            }
        })
    }
}
