//
//  FileReader.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public protocol FileReaderLoader {
    typealias Result = Swift.Result<Data, Swift.Error>
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
