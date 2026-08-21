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
    
    // MARK: - Helpers
    
    private let testKey = "test_beginner_completed_puzzles"
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> UserDefaultsBeginnerProgressStore {
        let sut = UserDefaultsBeginnerProgressStore(userDefaults: .standard, key: testKey)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }

}
