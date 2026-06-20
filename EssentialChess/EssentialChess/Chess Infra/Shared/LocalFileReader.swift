//
//  LocalFileReader.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public final class LocalFileReader: FileReaderLoader {
    
    public init() {}
    
    public func get(from url: URL, completion: @escaping (FileReaderLoader.Result) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {  [weak self] in
            guard self != nil else { return }
            do {
                let data = try Data(contentsOf: url)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
