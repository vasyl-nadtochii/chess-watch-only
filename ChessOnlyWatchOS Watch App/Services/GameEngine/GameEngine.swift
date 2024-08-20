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
    internal let defaults: IDefaults

    init(defaults: IDefaults, fenString: String = Constants.initialChessPosition) {
        self.defaults = defaults
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

    internal func precomputedMoveData() {
        self.numberOfSquaresToEdge = Array(
            repeating: Array(repeating: 0, count: 8),
            count: 64
        )
        for file in 0..<8 {
            for rank in 0..<8 {
                let numNorth = 7 - rank
                let numSouth = rank
                let numWest = file
                let numEast = 7 - file

                let squareIndex = rank * 8 + file

                numberOfSquaresToEdge[squareIndex] = [
                    numNorth,
                    numSouth,
                    numWest,
                    numEast,
                    min(numNorth, numWest),
                    min(numSouth, numEast),
                    min(numNorth, numEast),
                    min(numSouth, numWest)
                ]
            }
        }
    }

    internal func toggleSideToMove() {
        sideToMove = (sideToMove == Piece.white) ? Piece.black : Piece.white
        if sideToMove == opponentToPlayerSide && gameMode == .playerVsAI {
            makeComputerMove()
        }
    }
}
