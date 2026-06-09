//
//  FileCurriculumLoaderTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import XCTest
import EssentialChess

public final class FileCurriculumLoader {
    private let url: URL
    private let reader: FileReaderLoader
    
    public enum Error: Swift.Error {
        case readError
        case invalidData
    }
    
    //public typealias Result = FileReaderLoader.Result
    public typealias Result = Swift.Result<Data, Error>
    
    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        reader.get(from: url, completion: { result in
            switch result {
            case .failure:
                completion(.failure(.readError))
                
            case let .success(data):
                completion(.success(data))
            }
        })
    }
}

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
                capturedErrors.append(error)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
        }
        
        let readerError = NSError(domain: "Test", code: 0)
        reader.complete(with: readerError)
        
        XCTAssertEqual(capturedErrors, [.readError])
    }
    
    // MARK: - Helpers
    
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
