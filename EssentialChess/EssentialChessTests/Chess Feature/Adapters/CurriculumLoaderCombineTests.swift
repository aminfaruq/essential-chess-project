//
//  CurriculumLoaderCombineTests.swift
//  EssentialChessTests
//

import XCTest
import Combine
import EssentialChess

final class CurriculumLoaderCombineTests: XCTestCase {
    
    func test_publisher_deliversSuccessOnLoaderSuccess() {
        let loader = CurriculumLoaderSpy()
        let sut = loader.publisher()
        
        let expectedCurriculum = makeCurriculum()
        
        var receivedCurriculums = [Curriculum]()
        var receivedErrors = [Error]()
        
        let exp = expectation(description: "Wait for publisher")
        let cancellable = sut.sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                receivedErrors.append(error)
            }
            exp.fulfill()
        }, receiveValue: { curriculum in
            receivedCurriculums.append(curriculum)
        })
        
        loader.complete(with: expectedCurriculum)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedCurriculums, [expectedCurriculum])
        XCTAssertTrue(receivedErrors.isEmpty)
        cancellable.cancel()
    }
    
    func test_publisher_deliversErrorOnLoaderFailure() {
        let loader = CurriculumLoaderSpy()
        let sut = loader.publisher()
        
        let expectedError = NSError(domain: "test", code: 0)
        
        var receivedErrors = [Error]()
        
        let exp = expectation(description: "Wait for publisher")
        let cancellable = sut.sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                receivedErrors.append(error)
            }
            exp.fulfill()
        }, receiveValue: { _ in })
        
        loader.complete(with: expectedError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedErrors as [NSError], [expectedError])
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private func makeCurriculum() -> Curriculum {
        let metadata = CurriculumMetadata(description: "test", totalSections: 0, targetPuzzlesPerSubTheme: 0, targetPuzzlesPerExam: nil)
        return Curriculum(version: "1.0", metadata: metadata, sections: [])
    }
    
    private class CurriculumLoaderSpy: CurriculumLoader {
        private var completions = [(CurriculumLoader.Result) -> Void]()
        
        func load(completion: @escaping (CurriculumLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func complete(with curriculum: Curriculum, at index: Int = 0) {
            completions[index](.success(curriculum))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
    }
}
