//
//  MixPoolLoaderCombineTests.swift
//  EssentialChessTests
//

import XCTest
import Combine
import EssentialChess

final class MixPoolLoaderCombineTests: XCTestCase {
    
    func test_publisher_deliversSuccessOnLoaderSuccess() {
        let loader = MixPoolLoaderSpy()
        let sut = loader.publisher()
        
        let expectedMixPool = makeMixPool()
        
        var receivedMixPools = [MixPool]()
        var receivedErrors = [Error]()
        
        let exp = expectation(description: "Wait for publisher")
        let cancellable = sut.sink(receiveCompletion: { completion in
            switch completion {
            case .finished: break
            case let .failure(error):
                receivedErrors.append(error)
            }
            exp.fulfill()
        }, receiveValue: { pool in
            receivedMixPools.append(pool)
        })
        
        loader.complete(with: expectedMixPool)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedMixPools, [expectedMixPool])
        XCTAssertTrue(receivedErrors.isEmpty)
        cancellable.cancel()
    }
    
    func test_publisher_deliversErrorOnLoaderFailure() {
        let loader = MixPoolLoaderSpy()
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
    
    private func makeMixPool() -> MixPool {
        let metadata = MixPoolMetadata(totalPuzzles: 0, supportedModes: [])
        return MixPool(id: "1", metadata: metadata, difficultyTiers: [])
    }
    
    private class MixPoolLoaderSpy: MixPoolLoader {
        private var completions = [(MixPoolLoader.Result) -> Void]()
        
        func load(completion: @escaping (MixPoolLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func complete(with pool: MixPool, at index: Int = 0) {
            completions[index](.success(pool))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
    }
}
