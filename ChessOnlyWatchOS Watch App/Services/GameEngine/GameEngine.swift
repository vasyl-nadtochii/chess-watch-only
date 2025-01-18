//
//  GameEngine.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class GameEngine {

    enum Result {
        case pawnShouldBePromoted(pawn: Int, pawnIndex: Int)
        case pawnPromoted
        case playerSideUpdated
        case sideToMoveChanged
        
        case madePlainMove
        case capturedPiece
        case madeCastleMove
    }

    enum GameMode {
        case playerVsPlayer
        case playerVsAI
    }

    var sideToMove: Int {
        didSet {
            if sideToMove != oldValue {
                onResult?(.sideToMoveChanged)
            }
        }
    }

    var boardPosition: BoardPosition {
        return (playerSide == Piece.white) ? .whiteBelowBlackAbove : .blackBelowWhiteAbove
    }

    var opponentToPlayerSide: Int {
        return (playerSide == Piece.white) ? Piece.black : Piece.white
    }

    var playerIsChecked: Bool {
        let playerKing = Piece.king | playerSide
        return getAllAvailableAttackMoves(forSide: opponentToPlayerSide)
            .contains(where: { board[$0.targetSquare] == playerKing })
    }

    var board: [Int: Int]
    var playerSide: Int
    var onResult: ((Result) -> Void)?
    var movesHistory: [Move] = []
    var gameMode: GameMode = .playerVsAI

    internal var directionOffsets: [Int] = [8, -8, -1, 1, 7, -7, 9, -9]
    internal var numberOfSquaresToEdge: [[Int]] = []
    internal var enPassantSquareIndex: Int?
    internal var castlingRights: [Int: [CastlingSide: Bool]]

    // initial position
    internal let fenString: String
    internal var defaults: IDefaults
    internal let aiEngine: AIEngine

    init(defaults: IDefaults, aiEngine: AIEngine, fenString: String = Constants.initialChessPosition) {
        self.defaults = defaults
        self.aiEngine = aiEngine
        self.fenString = fenString
        self.board = [:]
        self.playerSide = defaults.playerSide
        self.sideToMove = defaults.playerSide
        self.castlingRights = [
            Piece.white: [
                .kingSide: false,
                .queenSide: false
            ],
            Piece.black: [
                .kingSide: false,
                .queenSide: false
            ]
        ]

        loadPositionsFromFEN(fenString)
        precomputedMoveData()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.playerSide = defaults.playerSide
            self.onResult?(.playerSideUpdated)
        }
    }

    internal func checkIfSideIsUnderCheck(_ side: Int) -> Bool {
        guard let kingPositionForSide = board.keys.first(where: { board[$0] == Piece.king | side }) else {
            print("Error: no king for side \(side)")
            return false
        }
        return checkIfPieceIsUnderAttack(pieceSide: side, piecePosition: kingPositionForSide)
    }

    internal func toggleSideToMove() {
        sideToMove = (sideToMove == Piece.white) ? Piece.black : Piece.white
        if sideToMove == opponentToPlayerSide && gameMode == .playerVsAI {
            self.makeComputerMove()
        }
    }

    internal func getPiecesMap() -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: 8), count: 8)
        for rowIndex in 0...7 {
            for columnIndex in 0...7 {
                matrix[rowIndex][columnIndex] = board[rowIndex * 8 + columnIndex] ?? 0
            }
        }
        return matrix
    }
}
