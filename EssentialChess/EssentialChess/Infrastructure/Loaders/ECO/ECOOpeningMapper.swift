//
//  ECOOpeningMapper.swift
//  EssentialChess
//

import Foundation

public final class ECOOpeningMapper {
    
    private struct DTO: Decodable {
        let eco: String
        let name: String
    }
    
    static func map(_ data: Data) -> FileECOLoader.Result {
        do {
            let dict = try JSONDecoder().decode([String: DTO].self, from: data)
            let openings = dict.mapValues { ECOOpening(eco: $0.eco, name: $0.name) }
            return .success(openings)
        } catch {
            return .failure(FileECOLoader.Error.invalidData)
        }
    }
}
