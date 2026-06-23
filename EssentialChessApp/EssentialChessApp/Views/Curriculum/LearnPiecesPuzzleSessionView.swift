import SwiftUI
import EssentialChess
import EssentialChessUI
import NativeChessBoard

public struct LearnPiecesPuzzleSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var composer: AppComposer
    @EnvironmentObject var container: DependencyContainer
    
    let title: String
    let puzzles: [PuzzleUIModel]
    
    @State private var currentActiveIndex: Int
    @State private var isSolved = false
    @State private var isSessionComplete = false
    @State private var showSequenceList = false
    @StateObject private var boardController = ChessBoardController()
    
    public init(title: String, puzzles: [PuzzleUIModel], initialIndex: Int) {
        self.title = title
        self.puzzles = puzzles
        self._currentActiveIndex = State(initialValue: initialIndex)
    }
    
    private var currentPuzzle: PuzzleUIModel? {
        guard currentActiveIndex < puzzles.count else { return nil }
        return puzzles[currentActiveIndex]
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if isSessionComplete {
                sessionCompletedView
            } else if let puzzle = currentPuzzle {
                VStack(spacing: 0) {
                    puzzleProgress
                    Spacer(minLength: 8)
                    boardArea(puzzle: puzzle)
                    playerTurnInfo
                        .padding(.top)
                    Spacer(minLength: 8)
                    controls
                }
            } else {
                Text("No puzzles available.")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationTitle(LocalizedStringKey(title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(isSessionComplete)
        .sheet(isPresented: $showSequenceList) {
            LearnPiecesSequenceListView(
                puzzles: puzzles,
                currentIndex: $currentActiveIndex,
                isPresented: $showSequenceList
            )
        }
    }
    
    // MARK: - Subviews
    
    private var puzzleProgress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Puzzle \(currentActiveIndex + 1) of \(puzzles.count)")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            ProgressBarView(progress: puzzles.isEmpty ? 0 : Double(currentActiveIndex) / Double(puzzles.count))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func boardArea(puzzle: PuzzleUIModel) -> some View {
        // Map PuzzleUIModel to Domain Puzzle for the bridge
        let domainPuzzle = Puzzle(
            id: puzzle.id,
            fen: puzzle.fen,
            moves: puzzle.moves,
            rating: puzzle.rating,
            tags: puzzle.tags
        )
        
        return LearnPiecesBoardBridge(
            puzzle: domainPuzzle,
            controller: boardController,
            onCompleted: {
                isSolved = true
                container.beginnerProgressStore.markCompleted(puzzleID: domainPuzzle.id)
            },
            onWrong: {
                // Do nothing for beginner mode or show a shake animation via controller if available
            },
            onReady: { color in
                boardController.userColorName = color
            },
            boardThemeLight: Color(
                red: themeAdapter.currentTheme.boardTheme.lightSquareColor.red,
                green: themeAdapter.currentTheme.boardTheme.lightSquareColor.green,
                blue: themeAdapter.currentTheme.boardTheme.lightSquareColor.blue,
                opacity: themeAdapter.currentTheme.boardTheme.lightSquareColor.alpha
            ),
            boardThemeDark: Color(
                red: themeAdapter.currentTheme.boardTheme.darkSquareColor.red,
                green: themeAdapter.currentTheme.boardTheme.darkSquareColor.green,
                blue: themeAdapter.currentTheme.boardTheme.darkSquareColor.blue,
                opacity: themeAdapter.currentTheme.boardTheme.darkSquareColor.alpha
            ),
            pieceTheme: themeAdapter.currentTheme.pieceTheme,
            isHapticEnabled: composer.settingsVM.isHapticEnabled,
            isSoundEnabled: composer.settingsVM.isSoundEnabled
        )
        .equatable()
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var controls: some View {
        HStack(spacing: 12) {
            Button { showSequenceList = true } label: {
                Label("Puzzles", systemImage: "list.number")
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .hoverEffect(.highlight)
            
            Spacer()
            
            if isSolved {
                Button { triggerNext() } label: {
                    Label("Next", systemImage: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .hoverEffect(.highlight)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private func triggerNext() {
        isSolved = false
        if currentActiveIndex + 1 < puzzles.count {
            currentActiveIndex += 1
        } else {
            isSessionComplete = true
        }
    }
    
    private var playerTurnInfo: some View {
        HStack {
            if !boardController.userColorName.isEmpty {
                let colorPrefix = boardController.userColorName == "White" ? "w" : "b"
                let pieceImageName = "\(themeAdapter.currentTheme.pieceTheme)_\(colorPrefix)k"
                
                HStack(spacing: 12) {
                    Image(pieceImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                    
                    
                    let key = "\(boardController.userColorName) to Move"
                    Text(LocalizedStringKey(key))
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    private var sessionCompletedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("✓")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(AppColors.accent)
            Text("Theme Complete!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Button { dismiss() } label: {
                Text("Back to Themes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .hoverEffect(.highlight)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Sequence List View for Beginner Mode
struct LearnPiecesSequenceListView: View {
    let puzzles: [PuzzleUIModel]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                List {
                    ForEach(0..<puzzles.count, id: \.self) { i in
                        let completedIDs = container.beginnerProgressStore.currentProgress.completedPuzzleIDs
                        let completed = completedIDs.contains(puzzles[i].id)
                        let isCurrent = i == currentIndex
                        // Beginner puzzles are always unlocked
                        // let unlocked = true 
                        
                        Button {
                            currentIndex = i
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                Group {
                                    if isCurrent {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                    } else if completed {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .frame(width: 20)
                                
                                Text("Puzzle \(i + 1)")
                                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            isCurrent ? AppColors.accent.opacity(0.08) : AppColors.surface
                        )
                        .hoverEffect(.highlight)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Puzzle Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(AppColors.accent)
                        .hoverEffect(.highlight)
                }
            }
        }
    }
}
