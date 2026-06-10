//
//  LocalFileReaderTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class LocalFileReaderTests: XCTestCase {
    
    func test_get_deliversErrorOnInvalidURL() {
        let sut = LocalFileReader()
        let invalidURL = URL(fileURLWithPath: "/path/that/does/not/exist.json")
        
        let expectation = expectation(description: "Wait for file reading completion")
        
        sut.get(from: invalidURL) { result in
            switch result {
            case .failure:
                break // Success: We expect an error because the file doesn't exist
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_get_deliversDataOnValidURL() {
        let sut = LocalFileReader()
        
        // 1. Create a temporary file
        let temporaryFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let expectedData = Data("any data".utf8)
        try! expectedData.write(to: temporaryFileURL)
        
        // 2. Clean up the file after test finishes
        addTeardownBlock {
            try? FileManager.default.removeItem(at: temporaryFileURL)
        }
        
        let expectation = expectation(description: "Wait for file reading completion")
        
        // 3. Test the reader
        sut.get(from: temporaryFileURL) { result in
            switch result {
            case let .success(receivedData):
                XCTAssertEqual(receivedData, expectedData, "Expected to read the exact data we wrote to the file.")
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
