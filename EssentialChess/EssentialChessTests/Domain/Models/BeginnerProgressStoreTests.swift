import XCTest
import EssentialChess
import Combine

final class BeginnerProgressStoreTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    func test_init_loadsEmptyProgressWhenNoDataExists() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.currentProgress.completedPuzzleIDs.isEmpty)
    }
    
    func test_markCompleted_updatesProgressAndSavesToUserDefaults() {
        let sut = makeSUT()
        
        sut.markCompleted(puzzleID: "puzzle_1")
        
        XCTAssertEqual(sut.currentProgress.completedPuzzleIDs, ["puzzle_1"])
        
        // Verify it was saved to UserDefaults
        let saved = UserDefaults.standard.stringArray(forKey: testKey) ?? []
        XCTAssertEqual(Set(saved), ["puzzle_1"])
    }
    
    func test_init_loadsExistingProgressFromUserDefaults() {
        UserDefaults.standard.set(["puzzle_1", "puzzle_2"], forKey: testKey)
        
        let sut = makeSUT()
        
        XCTAssertEqual(sut.currentProgress.completedPuzzleIDs, ["puzzle_1", "puzzle_2"])
    }
    
    func test_clearProgress_removesDataFromUserDefaultsAndResetsState() {
        let sut = makeSUT()
        sut.markCompleted(puzzleID: "puzzle_1")
        
        sut.clearProgress()
        
        XCTAssertTrue(sut.currentProgress.completedPuzzleIDs.isEmpty)
        XCTAssertNil(UserDefaults.standard.array(forKey: testKey))
    }
    
    func test_progressPublisher_emitsUpdatesOnCompletion() {
        let sut = makeSUT()
        
        var emittedProgresses: [BeginnerProgress] = []
        let cancellable = sut.progressPublisher.sink { progress in
            emittedProgresses.append(progress)
        }
        
        sut.markCompleted(puzzleID: "p1")
        sut.markCompleted(puzzleID: "p2")
        
        XCTAssertEqual(emittedProgresses.count, 3) // Initial + 2 updates
        XCTAssertEqual(emittedProgresses[0].completedPuzzleIDs, [])
        XCTAssertEqual(emittedProgresses[1].completedPuzzleIDs, ["p1"])
        XCTAssertEqual(emittedProgresses[2].completedPuzzleIDs, ["p1", "p2"])
        
        cancellable.cancel()
    }
    
    // MARK: - Helpers
    
    private let testKey = "test_beginner_completed_puzzles"
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> UserDefaultsBeginnerProgressStore {
        let sut = UserDefaultsBeginnerProgressStore(userDefaults: .standard, key: testKey)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }

}
