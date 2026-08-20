//
//  FileECOLoader.swift
//  EssentialChess
//

import Foundation

public final class FileECOLoader: ECOLoader {
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
    
    public func load(completion: @escaping (ECOLoader.Result) -> Void) {
        reader.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data):
                completion(ECOOpeningMapper.map(data))
            case .failure:
                completion(.failure(Error.readError))
            }
        }
    }
}
