//
//  FileReader.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public protocol FileReader {
    typealias Result = Swift.Result<Data, Error>
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
