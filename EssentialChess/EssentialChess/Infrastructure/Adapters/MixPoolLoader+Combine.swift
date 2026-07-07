//
//  MixPoolLoader+Combine.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine

public extension MixPoolLoader {
    func publisher() -> AnyPublisher<MixPool, Error> {
        return Deferred {
            Future { promise in
                self.load(completion: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}
