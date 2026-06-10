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
        
    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
}

extension FileMixPoolLoader: MixPoolLoader {
    public func load(completion: @escaping (MixPoolLoader.Result) -> Void) {
        reader.get(from: url, completion: { result in
            switch result {
            case let .success(data):
                completion(MixPoolMapper.map(data))
            default:
                completion(.failure(Error.readError))
            }
        })
    }
}
