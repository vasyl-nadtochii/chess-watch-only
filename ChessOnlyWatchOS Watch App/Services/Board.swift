//
//  Board.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class Board {

    enum Result {
        case pawnShouldBePromoted(pawn: Int, pawnIndex: Int)
    }

    var sideToMove: Int
    var squares: [Int]
    var playerSide: Int
    var boardPosition: BoardPosition
    var onResult: ((Result) -> Void)?

    private var directionOffsets: [Int] = [8, -8, -1, 1, 7, -7, 9, -9]
    private var numberOfSquaresToEdge: [[Int]] = []

    var opponentSide: Int {
        return (playerSide == Piece.white) ? Piece.black : Piece.white
    }

    // initial position
    // let fenString = Constants.initialChessPosition
    let fenString = "8/8/8/8/8/8/3p4/8" // just for test

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.squares = Array(repeating: 0, count: 64)
        self.playerSide = defaults.playerSide
        self.sideToMove = defaults.playerSide
        self.boardPosition = defaults.boardPosition

        loadPositionsFromFEN(fenString)
        precomputedMoveData()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.playerSide = defaults.playerSide
        }
    }

    func getAvailableSlidingMoves(at startIndex: Int, for piece: Int) -> [Move] {
        let startDirectionIndex = (Piece.pieceType(from: piece) == Piece.bishop) ? 4 : 0
        let endDirectionIndex = (Piece.pieceType(from: piece) == Piece.rook) ? 4 : 8

        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]

        for directionIndex in startDirectionIndex..<endDirectionIndex {
            for n in 0..<numberOfSquaresToEdge[startIndex][directionIndex] {
                let targetSquareIndex = startIndex + directionOffsets[directionIndex] * (n + 1)
                let pieceOnTargetSquare = squares[targetSquareIndex]

                if Piece.pieceColor(from: pieceOnTargetSquare) == playerSide {
                    break
                }

                moves.append(.init(startSquare: startIndex, targetSquare: targetSquareIndex))

                if Piece.pieceColor(from: pieceOnTargetSquare) == opponentSide {
                    break
                }
            }
        }

        return moves
    }

    func getAvailablePawnMoves(at startIndex: Int, for piece: Int) -> [Move] {
        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]
        let pieceColor = Piece.pieceColor(from: piece)

        var oneStepForward = 8
        var twoStepForward = 16
        var attackSteps = [7, 9]

        // MARK: Define direction
        if (pieceColor == Piece.white && boardPosition == .blackBelowWhiteAbove)
            || (pieceColor == Piece.black && boardPosition == .whiteBelowBlackAbove) {
            oneStepForward *= -1
            twoStepForward *= -1
            attackSteps = attackSteps.map({ $0 * -1 })
        }

        // MARK: Handle one step forward (regular move)
        if startIndex + oneStepForward < 64
            && startIndex + oneStepForward >= 0
            && squares[startIndex + oneStepForward] == 0 {
            moves.append(.init(startSquare: startIndex, targetSquare: startIndex + oneStepForward))
        }

        // MARK: Handle two steps forward (initial move)
        if boardPosition == .whiteBelowBlackAbove
            && ((pieceColor == Piece.white && (startIndex >= 8 && startIndex < 16))
                || (pieceColor == Piece.black && (startIndex >= 48 && startIndex < 56)))
            && squares[startIndex + twoStepForward] == 0 {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + twoStepForward))
        } else if boardPosition == .blackBelowWhiteAbove
            && ((pieceColor == Piece.black && (startIndex >= 8 && startIndex < 16))
                || (pieceColor == Piece.white && (startIndex >= 48 && startIndex < 56)))
            && squares[startIndex + twoStepForward] == 0 {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + twoStepForward))
        }

        // MARK: Handle attack move
        for attackStep in attackSteps {
            if squares[startIndex + attackStep] != 0 {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + attackStep))
            }
        }

        // TODO: Handle En passant scenario

        return moves
    }

    func precomputedMoveData() {
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

    func makeMove(move: Move, piece: Int) -> Bool {
        guard move.startSquare != move.targetSquare else { return false }
        guard sideToMove == Piece.pieceColor(from: piece) else {
            return false
        }
        squares[move.startSquare] = 0
        squares[move.targetSquare] = piece

        if Piece.pieceType(from: piece) == Piece.pawn && checkPawnPromotion(move: move, piece: piece) {
            onResult?(.pawnShouldBePromoted(pawn: piece, pawnIndex: move.targetSquare))
            // TODO: also, when there is a timer implemented, we should pause it unless player finishes promotion
        }

        // TODO: Check for check/checkmate

        toggleSideToMove()

        return true
    }

    func promotePawn(at squareIndex: Int, from pawn: Int, to newPieceType: Int) {
        guard let pawnColor = Piece.pieceColor(from: pawn) else { return }
        squares[squareIndex] = newPieceType | pawnColor
    }

    private func loadPositionsFromFEN(_ fenString: String) {
        let pieceTypeFromSymbol: [Character: Int] = [
            "k": Piece.king,
            "p": Piece.pawn,
            "n": Piece.knight,
            "b": Piece.bishop,
            "r": Piece.rook,
            "q": Piece.queen
        ]

        let fenBoard = fenString.split(separator: " ")[0]
        var file = 0
        var rank = 7

        for symbol in fenBoard {
            if symbol == "/" {
                file = 0
                rank -= 1
            } else {
                if symbol.isNumber, let number = symbol.wholeNumberValue {
                    file += number
                } else {
                    let pieceColor = symbol.isUppercase ? Piece.white : Piece.black
                    let pieceType = pieceTypeFromSymbol[Character(symbol.lowercased())]
                    squares[rank * 8 + file] = (pieceType ?? 0) | pieceColor
                    file += 1
                }
            }
        }
    }

    private func toggleSideToMove() {
        sideToMove = (sideToMove == Piece.white) ? Piece.black : Piece.white
    }

    private func checkPawnPromotion(move: Move, piece: Int) -> Bool {
        var startOfPromotionZone = 0
        var endOfPromotionZone = 7

        if (boardPosition == .whiteBelowBlackAbove && Piece.pieceColor(from: piece) == Piece.white)
            || (boardPosition == .blackBelowWhiteAbove && Piece.pieceColor(from: piece) == Piece.black) {
            startOfPromotionZone = 56
            endOfPromotionZone = 63
        }

        if move.targetSquare >= startOfPromotionZone && move.targetSquare <= endOfPromotionZone {
            return true
        }

        return false
    }
}
