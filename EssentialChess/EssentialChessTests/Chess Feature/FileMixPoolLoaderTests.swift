//
//  FileMixPoolLoaderTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class FileMixPoolLoaderTests: XCTestCase {
    
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
        
        var capturedErrors = [FileMixPoolLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error)
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
        
        var capturedErrors = [FileMixPoolLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
        
        let invalidData = Data("not JSON".utf8)
        reader.complete(with: invalidData)
        
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    func test_load_deliversSuccessOnValidJSONData() {
        let (sut, reader) = makeSUT()
        
        let (expectedModel, validJSON) = makeMixPool()
        let jsonData = try! JSONSerialization.data(withJSONObject: validJSON)
        
        var capturedResults = [FileMixPoolLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        reader.complete(with: jsonData)
        
        XCTAssertEqual(capturedResults, [.success(expectedModel)])
    }
    
    // MARK: - Helpers
    
    private func makeMixPool() -> (model: MixPool, json: [String: Any]) {
        let puzzle = Puzzle(id: "p1", fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", moves: ["e2e4"], rating: 1200, tags: ["pin"])
        
        let tier = DifficultyTier(id: "t1", displayName: "Beginner", eloRange: "0-500", accentColorHex: "#FFFFFF", description: "Easy puzzles", puzzles: [puzzle])
        
        let metadata = MixPoolMetadata(totalPuzzles: 1, supportedModes: ["survival"])
        
        let model = MixPool(id: "pool1", metadata: metadata, difficultyTiers: [tier])
        
        let json: [String: Any] = [
            "mix_pool_id": "pool1",
            "metadata": [
                "total_puzzles": 1,
                "supported_modes": ["survival"]
            ] as [String : Any],
            "difficulty_tiers": [
                [
                    "tier_id": "t1",
                    "display_name": "Beginner",
                    "elo_range": "0-500",
                    "accent_color_hex": "#FFFFFF",
                    "description": "Easy puzzles",
                    "puzzles": [
                        [
                            "id": "p1",
                            "fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                            "moves": ["e2e4"],
                            "rating": 1200,
                            "hidden_theme": "pin"
                        ] as [String : Any]
                    ]
                ] as [String : Any]
            ]
        ]
        
        return (model, json)
    }
    
    private func makeSUT(url: URL = URL(fileURLWithPath: "/any-url.json"), file: StaticString = #filePath, line: UInt = #line) -> (sut: FileMixPoolLoader, reader: FileReaderSpy) {
        let reader = FileReaderSpy()
        let sut = FileMixPoolLoader(url: url, reader: reader)
        
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
