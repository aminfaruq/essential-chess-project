import SwiftUI
import EssentialChess
import EssentialChessUI
import ChessBoard

public struct LearnPiecesPuzzleSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeAdapter: ThemeAdapter
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var container: DependencyContainer
    
    let themeId: String?
    let title: String
    let puzzles: [PuzzleUIModel]
    
    @State private var currentActiveIndex: Int
    @State private var isSolved = false
    @State private var isSessionComplete = false
    @State private var showSequenceList = false
    @StateObject private var boardController = ChessBoardController()
    
    public init(themeId: String? = nil, title: String, puzzles: [PuzzleUIModel], initialIndex: Int) {
        self.themeId = themeId
        self.title = title
        self.puzzles = puzzles
        self._currentActiveIndex = State(initialValue: initialIndex)
    }
    
    private var currentPuzzle: PuzzleUIModel? {
        guard currentActiveIndex < puzzles.count else { return nil }
        return puzzles[currentActiveIndex]
    }
    
    private var descriptionText: String? {
        switch themeId {
        case "sub_move_rook":
            return "The rook moves in straight lines, either horizontally along ranks or vertically along files, for any number of unoccupied squares. It cannot jump over other pieces, but it captures an enemy piece by landing on the square it occupies."
        case "sub_move_bishop":
            return "The bishop moves any number of squares diagonally in any direction, provided the path is clear. It cannot jump over other pieces and must stay on the same square color for the entire game. To capture, the bishop moves to a square occupied by an opponent's piece and removes it from the board."
        case "sub_move_queen":
            return "The queen is the most powerful piece in chess, able to move any number of squares horizontally, vertically, or diagonally in a straight line. It combines the movement powers of the rook and the bishop but cannot jump over other pieces. The queen captures an opponent's piece by landing on the square it occupies."
        case "sub_move_king":
            return "The king moves exactly one square in any direction: horizontally, vertically, or diagonally. It is the most important piece but has limited mobility, and it can never move onto a square that is under attack by an enemy piece."
        case "sub_move_knight":
            return "The knight moves in an L-shape: two squares in one direction (vertically or horizontally) and then one square perpendicularly. It is the unique piece that can jump over other pieces, and it always lands on a square of the opposite color from its starting position."
        case "sub_move_pawn":
            return "The pawn moves directly forward one square at a time, but on its first move, it can advance two squares if both are vacant. It captures by moving one square diagonally forward to the left or right, and it is the only piece that captures differently than it moves. If a pawn reaches the opposite end of the board, it is promoted to any piece except a king, and it can also perform the special en passant capture."
        default:
            return nil
        }
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            if isSessionComplete {
                sessionCompletedView
            } else if let puzzle = currentPuzzle {
                VStack(spacing: 0) {
                    puzzleProgress
                    
                    if let text = descriptionText {
                        ScrollView(showsIndicators: true) {
                            Text(LocalizedStringKey(text))
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                        .frame(maxHeight: 80)
                        .background(AppColors.surface.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    Spacer(minLength: 8)
                    boardArea(puzzle: puzzle)
                   
//                    playerTurnInfo
//                        .padding(.top)
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
                container.progressAdapter.update { $0.recordActivity() }
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
            isHapticEnabled: settingsVM.isHapticEnabled,
            isSoundEnabled: settingsVM.isSoundEnabled
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
            Text(LocalizedStringKey(title))
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
