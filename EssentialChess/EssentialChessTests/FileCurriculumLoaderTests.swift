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
    
    public typealias Result = FileReaderLoader.Result

    public init(url: URL, reader: FileReaderLoader) {
        self.url = url
        self.reader = reader
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        reader.get(from: url, completion: { _ in })
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
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(fileURLWithPath: "/any-url.json"), file: StaticString = #filePath, line: UInt = #line) -> (sut: FileCurriculumLoader, reader: FileReaderSpy) {
        let reader = FileReaderSpy()
        let sut = FileCurriculumLoader(url: url, reader: reader)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(reader, file: file, line: line)
        
        return (sut, reader)
    }
    
    private class FileReaderSpy: FileReaderLoader {
        
        
        var requestedURLs = [URL]()
        
        func get(from url: URL, completion: @escaping (FileReaderLoader.Result) -> Void) {
            requestedURLs.append(url)
        }
    }
}
