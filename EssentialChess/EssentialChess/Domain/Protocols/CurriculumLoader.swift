//
//  Untitled.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public protocol CurriculumLoader {
    typealias Result = Swift.Result<Curriculum, Swift.Error>

    func load(completion: @escaping (Result) -> Void)
}
