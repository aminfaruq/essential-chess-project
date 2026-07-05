//
//  CloudEvaluationMapperTests.swift
//  EssentialChessTests
//

import XCTest
@testable import EssentialChess

final class CloudEvaluationMapperTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let json = validJSON()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 404, httpVersion: nil, headerFields: nil)!
        
        XCTAssertThrowsError(try CloudEvaluationMapper.map(json, response: response))
    }
    
    func test_map_throwsErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid".utf8)
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        XCTAssertThrowsError(try CloudEvaluationMapper.map(invalidJSON, response: response))
    }
    
    func test_map_deliversEvaluationOn200HTTPResponseWithValidJSON() throws {
        let json = validJSON()
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let evaluation = try CloudEvaluationMapper.map(json, response: response)
        
        XCTAssertEqual(evaluation.fen, "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R")
        XCTAssertEqual(evaluation.depth, 29)
        XCTAssertEqual(evaluation.pvs.count, 1)
        XCTAssertEqual(evaluation.pvs[0].moves, "d1e2 d8e7")
        XCTAssertEqual(evaluation.pvs[0].cp, 41)
        XCTAssertNil(evaluation.pvs[0].mate)
    }
    
    // MARK: - Helpers
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func validJSON() -> Data {
        return """
        {
          "fen": "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R",
          "knodes": 106325,
          "depth": 29,
          "pvs": [
            {
              "moves": "d1e2 d8e7",
              "cp": 41
            }
          ]
        }
        """.data(using: .utf8)!
    }
}
