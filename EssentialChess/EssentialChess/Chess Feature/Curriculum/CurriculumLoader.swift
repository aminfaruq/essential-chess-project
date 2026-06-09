//
//  Untitled.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public enum LoadCurriculumResult {
    case success(Curriculum)
    case failure(Error)
}

public protocol CurriculumLoader {
    func load(completion: @escaping (LoadCurriculumResult) -> Void)
}
