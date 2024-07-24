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

    var board: [Int: Int]
    var playerSide: Int
    var onResult: ((Result) -> Void)?
    var movesHistory: [Move] = []
    var gameMode: GameMode = .playerVsPlayer

    internal var directionOffsets: [Int] = [8, -8, -1, 1, 7, -7, 9, -9]
    internal var numberOfSquaresToEdge: [[Int]] = []
    internal var enPassantSquareIndex: Int?
    internal var castlingRights: [Int: [CastlingSide: Bool]]

    // initial position
    internal let fenString: String
//    private let fenString = "4k3/8/8/2Q3B1/8/8/8/3K1R2 w -" // just for test
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

    // MARK: Computer

    internal func makeComputerMove() {
        guard let move = chooseComputerMove() else {
            print("Computer doesn't have available moves to pick")
            return
        }
        guard let pieceThatComputerPicked = board[move.startSquare] else {
            print("Computer picked empty cell")
            return
        }
        _ = makeMove(move: move, piece: pieceThatComputerPicked)
    }

    internal func chooseComputerMove() -> Move? {
        let moves = getAllAvailableMoves(forSide: opponentToPlayerSide).filter({ $0.startSquare != $0.targetSquare })
        return moves.randomElement()
    }

    internal func promoteComputerPawn(at index: Int) {
        let pieces = [Piece.queen, Piece.bishop, Piece.knight, Piece.rook]
        let promotionPiece = pieces.randomElement() ?? Piece.queen
        promotePawn(at: index, from: (opponentToPlayerSide | Piece.pawn), to: promotionPiece)
    }
}
