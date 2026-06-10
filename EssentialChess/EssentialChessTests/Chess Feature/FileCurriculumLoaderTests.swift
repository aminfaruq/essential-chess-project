//
//  FileCurriculumLoaderTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import XCTest
import EssentialChess

final class FileCurriculumLoaderTests: XCTestCase {
    
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
    
    func test_loadTwice_requestsDataFromDataFromURLTwice() {
        let url = URL(fileURLWithPath: "/a-given-url.json")
        let (sut, reader) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(reader.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnReaderError() {
        let (sut, reader) = makeSUT()
        
        var capturedErrors = [FileCurriculumLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error as! FileCurriculumLoader.Error)
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
        
        var capturedErrors = [FileCurriculumLoader.Error]()
        sut.load { result in
            switch result {
            case let .failure(error):
                capturedErrors.append(error as! FileCurriculumLoader.Error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
        
        let invalidData = Data("Not JSON".utf8)
        reader.complete(with: invalidData)
        
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    func test_load_deliversSuccesOnValidJsonData() {
        let (sut, reader) = makeSUT()
        
        let (expectedModel, validJSON) = makeCurriculum()
        let jsonData = try! JSONSerialization.data(withJSONObject: validJSON)
        
        var receivedResult: FileCurriculumLoader.Result?
        sut.load { receivedResult = $0 }
        
        reader.complete(with: jsonData)
        
        switch receivedResult {
        case let .success(model):
            XCTAssertEqual(model, expectedModel)
        default:
            XCTFail("Expected success, got \(String(describing: receivedResult)) instead")
        }
    }
    
    // MARK: - Helpers
    
    private func makeCurriculum() -> (model: Curriculum, json: [String: Any]) {
        let puzzle = Puzzle(id: "p1", fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", moves: ["e2e4"], rating: 1200, tags: ["opening"])
        
        let subTheme = SubTheme(id: "st1", title: "Basic Tactics", totalPuzzles: 1, puzzles: [puzzle])
        
        let category = Category(id: "c1", title: "Tactics", isExamMode: false, description: "Basic tactics category", totalPuzzles: 1, puzzles: nil, subThemes: [subTheme])
        
        let section = EloSection(id: "sec1", title: "Beginner", eloRange: "0-500", isLockedByDefault: false, categories: [category])
        
        let metadata = CurriculumMetadata(description: "Test Curriculum", totalSections: 1, targetPuzzlesPerSubTheme: 10, targetPuzzlesPerExam: nil)
        
        let model = Curriculum(version: "1.0", metadata: metadata, sections: [section])
        
        let json: [String: Any] = [
            "curriculum_version": "1.0",
            "metadata": [
                "description": "Test Curriculum",
                "total_sections": 1,
                "target_puzzles_per_sub_theme": 10
            ] as [String : Any],
            "elo_sections": [
                [
                    "section_id": "sec1",
                    "title": "Beginner",
                    "elo_range": "0-500",
                    "is_locked_by_default": false,
                    "categories": [
                        [
                            "category_id": "c1",
                            "title": "Tactics",
                            "is_exam_mode": false,
                            "description": "Basic tactics category",
                            "total_puzzles": 1,
                            "sub_themes": [
                                [
                                    "sub_theme_id": "st1",
                                    "title": "Basic Tactics",
                                    "total_puzzles": 1,
                                    "puzzles": [
                                        [
                                            "id": "p1",
                                            "fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                                            "moves": ["e2e4"],
                                            "rating": 1200,
                                            "tags": ["opening"]
                                        ] as [String : Any]
                                    ]
                                ] as [String : Any]
                            ]
                        ] as [String : Any]
                    ]
                ] as [String : Any]
            ]
        ]
        
        return (model, json)
    }
    
    private func makeSUT(url: URL = URL(fileURLWithPath: "/any-url.json"), file: StaticString = #filePath, line: UInt = #line) -> (sut: FileCurriculumLoader, reader: FileReaderSpy) {
        let reader = FileReaderSpy()
        let sut = FileCurriculumLoader(url: url, reader: reader)
        
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
        
        // Helpers
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }
    }
}

