//
//  FileCurriculumLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public final class FileCurriculumLoader {
    private let url: URL
    private let reader: FileReaderLoader
    
    public enum Error: Swift.Error {
        case readError
        case invalidData
    }
    
    public typealias Result = Swift.Result<Curriculum, Error>
    
    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        reader.get(from: url) { result in
            switch result {
            case let .success(data):
                completion(CurriculumMapper.map(data))
            case .failure:
                completion(.failure(.readError))
            }
        }
    }
}
