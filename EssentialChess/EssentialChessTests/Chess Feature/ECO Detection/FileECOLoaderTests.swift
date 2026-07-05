//
//  FileECOLoaderTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class FileECOLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, reader) = makeSUT()
        
        XCTAssertTrue(reader.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(fileURLWithPath: "/a-given-url.json")
        let (sut, reader) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(reader.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(fileURLWithPath: "/a-given-url.json")
        let (sut, reader) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(reader.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnReaderError() {
        let (sut, reader) = makeSUT()
        
        var capturedErrors = [FileECOLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error as! FileECOLoader.Error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
        
        let readerError = NSError(domain: "Test", code: 0)
        reader.complete(with: readerError)
        
        XCTAssertEqual(capturedErrors, [.readError])
    }
    
    func test_load_deliversErrorOnInvalidData() {
        let (sut, reader) = makeSUT()
        
        var capturedErrors = [FileECOLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error as! FileECOLoader.Error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
        
        let invalidData = Data("Not JSON".utf8)
        reader.complete(with: invalidData)
        
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    func test_load_deliversSuccessOnValidJSONData() {
        let (sut, reader) = makeSUT()
        
        let validJSON: [String: Any] = [
            "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": [
                "eco": "C20",
                "name": "King's Pawn Game"
            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: validJSON)
        
        let expectedDict: [String: ECOOpening] = [
            "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": ECOOpening(eco: "C20", name: "King's Pawn Game")
        ]
        
        var receivedResult: ECOLoader.Result?
        sut.load { receivedResult = $0 }
        
        reader.complete(with: jsonData)
        
        switch receivedResult {
        case let .success(dict):
            XCTAssertEqual(dict, expectedDict)
        default:
            XCTFail("Expected success, got \(String(describing: receivedResult)) instead")
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(fileURLWithPath: "/a-given-url.json")
        let client = FileReaderSpy()
        var sut: FileECOLoader? = FileECOLoader(url: url, reader: client)
        
        var capturedResults = [ECOLoader.Result]()
        sut?.load(completion: { capturedResults.append($0) })
        
        sut = nil
        
        let validJSON: [String: Any] = [
            "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": [
                "eco": "C20",
                "name": "King's Pawn Game"
            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: validJSON)

        client.complete(with: jsonData)
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(fileURLWithPath: "/any-url.json"), file: StaticString = #filePath, line: UInt = #line) -> (sut: FileECOLoader, reader: FileReaderSpy) {
        let reader = FileReaderSpy()
        let sut = FileECOLoader(url: url, reader: reader)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(reader, file: file, line: line)
        
        return (sut, reader)
    }
    
    private class FileReaderSpy: FileReaderLoader {
        private var messages = [(url: URL, completion: (FileReaderLoader.Result) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (FileReaderLoader.Result) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }
    }
}
