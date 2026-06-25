//
//  FileRepertoireLoader.swift
//  EssentialChess
//

import Foundation

public final class FileRepertoireLoader: RepertoireLoader {
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
    
    public func load(completion: @escaping (RepertoireLoader.Result) -> Void) {
        reader.get(from: url) { result in
            switch result {
            case let .success(data):
                do {
                    let nodes = try RepertoireMapper.map(data)
                    completion(.success(nodes))
                } catch {
                    completion(.failure(Error.invalidData))
                }
            case .failure:
                completion(.failure(Error.readError))
            }
        }
    }
}
