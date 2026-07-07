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
    
    public enum Error: Swift.Error, Equatable {
        case readError
        case invalidData(underlyingError: Swift.Error? = nil)
        
        public static func == (lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.readError, .readError):
                return true
            case (.invalidData, .invalidData):
                return true
            default:
                return false
            }
        }
    }
    
    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
}

extension FileCurriculumLoader: CurriculumLoader {
    
    public func load(completion: @escaping (CurriculumLoader.Result) -> Void) {
        reader.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data):
                completion(CurriculumMapper.map(data))
            case .failure:
                completion(.failure(Error.readError))
            }
        }
    }
}
