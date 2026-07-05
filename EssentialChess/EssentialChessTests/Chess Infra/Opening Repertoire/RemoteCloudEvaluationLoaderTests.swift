//
//  RemoteCloudEvaluationLoaderTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 05/07/26.
//

import XCTest
import EssentialChess

final class RemoteCloudEvaluationLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load(fen: anyFen()) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [expectedURL(for: anyFen())])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        let fen = anyFen()
        
        sut.load(fen: fen) { _ in }
        sut.load(fen: fen) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [expectedURL(for: fen), expectedURL(for: fen)])
    }
    
    func test_load_deliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteCloudEvaluationLoader.Error.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteCloudEvaluationLoader.Error.invalidData), when: {
                let json = validJSON()
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteCloudEvaluationLoader.Error.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversEvaluationOn200HTTPResponseWithValidJSON() {
        let (sut, client) = makeSUT()
        
        let expectedEvaluation = CloudEvaluation(
            fen: "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R",
            depth: 29,
            pvs: [
                PrincipalVariation(moves: "d1e2 d8e7", cp: 41, mate: nil)
            ]
        )
        
        expect(sut, toCompleteWith: .success(expectedEvaluation), when: {
            client.complete(withStatusCode: 200, data: validJSON())
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteCloudEvaluationLoader? = RemoteCloudEvaluationLoader(client: client)
        
        var capturedResults = [CloudEvaluationLoader.Result]()
        sut?.load(fen: anyFen()) { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: validJSON())
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteCloudEvaluationLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCloudEvaluationLoader(client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteCloudEvaluationLoader, toCompleteWith expectedResult: CloudEvaluationLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        var receivedResult: CloudEvaluationLoader.Result?
        sut.load(fen: anyFen()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        switch (receivedResult, expectedResult) {
        case let (.success(receivedEval), .success(expectedEval)):
            XCTAssertEqual(receivedEval, expectedEval, file: file, line: line)
        case let (.failure(receivedError as RemoteCloudEvaluationLoader.Error), .failure(expectedError as RemoteCloudEvaluationLoader.Error)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        default:
            XCTFail("Expected result \(expectedResult) got \(String(describing: receivedResult)) instead", file: file, line: line)
        }
    }
    
    private func anyFen() -> String {
        return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    }
    
    private func expectedURL(for fen: String) -> URL {
        let encodedFen = fen.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return URL(string: "https://lichess.org/api/cloud-eval?fen=\(encodedFen)&multiPv=3&variant=standard")!
    }
    
    private func validJSON() -> Data {
        return """
        {
          "fen": "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R",
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
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, headers: [String: String]?, completion: @escaping (HTTPClient.Result) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }
}

