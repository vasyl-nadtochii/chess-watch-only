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
        case playerSideUpdated
        case sideToMoveChanged
    }

    var sideToMove: Int {
        didSet {
            if sideToMove != oldValue {
                onResult?(.sideToMoveChanged)
            }
        }
    }

    var squares: [Int]
    var playerSide: Int
    var boardPosition: BoardPosition {
        return (playerSide == Piece.white) ? .whiteBelowBlackAbove : .blackBelowWhiteAbove
    }
    var onResult: ((Result) -> Void)?

    private var directionOffsets: [Int] = [8, -8, -1, 1, 7, -7, 9, -9]
    private var numberOfSquaresToEdge: [[Int]] = []

    var opponentSide: Int {
        return (playerSide == Piece.white) ? Piece.black : Piece.white
    }

    // initial position
    let fenString = Constants.initialChessPosition
    // let fenString = "3k4/8/8/8/2K5/8/8/8" // just for test

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.squares = Array(repeating: 0, count: 64)
        self.playerSide = defaults.playerSide
        self.sideToMove = defaults.playerSide // TODO: ?

        loadPositionsFromFEN(fenString)
        precomputedMoveData()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.playerSide = defaults.playerSide
            self.onResult?(.playerSideUpdated)
        }
    }

    func getAvailableMoves(at startIndex: Int?, for piece: Int?) -> [Move] {
        guard let selectedCellIndex = startIndex,
            let pieceAtCell = piece,
            let selectedPieceType = Piece.pieceType(from: pieceAtCell)
        else { return [] }

        switch selectedPieceType {
        case Piece.king:
            return getAvailableKingMoves(at: selectedCellIndex, for: pieceAtCell)
        case Piece.pawn:
            return getAvailablePawnMoves(at: selectedCellIndex, for: pieceAtCell)
        case Piece.bishop, Piece.queen, Piece.rook:
            return getAvailableSlidingMoves(at: selectedCellIndex, for: pieceAtCell)
        case Piece.knight:
            return getAvailableKnightMoves(at: selectedCellIndex, for: pieceAtCell)
        default:
            return []
        }
    }

    private func getAvailableSlidingMoves(at startIndex: Int, for piece: Int) -> [Move] {
        let startDirectionIndex = (Piece.pieceType(from: piece) == Piece.bishop) ? 4 : 0
        let endDirectionIndex = (Piece.pieceType(from: piece) == Piece.rook) ? 4 : 8

        let pieceColorOfSelectedPiece = Piece.pieceColor(from: piece)
        let oppositeColorToSelected = pieceColorOfSelectedPiece == Piece.white ? Piece.black : Piece.white

        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]

        for directionIndex in startDirectionIndex..<endDirectionIndex {
            for n in 0..<numberOfSquaresToEdge[startIndex][directionIndex] {
                let targetSquareIndex = startIndex + directionOffsets[directionIndex] * (n + 1)
                let pieceOnTargetSquare = squares[targetSquareIndex]

                if Piece.pieceColor(from: pieceOnTargetSquare) == pieceColorOfSelectedPiece {
                    break
                }

                moves.append(.init(startSquare: startIndex, targetSquare: targetSquareIndex))

                if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToSelected {
                    break
                }
            }
        }

        return moves
    }

    private func getAvailableKnightMoves(at startIndex: Int, for piece: Int) -> [Move] {
        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]
        var availableOffsets = [15, 17, -15, -17, 10, 6, -10, -6]
        let pieceColor = Piece.pieceColor(from: piece)

        for availableOffset in availableOffsets {
            if startIndex + availableOffset < 0 || startIndex + availableOffset >= 64 {
                availableOffsets.removeAll(where: { $0 == availableOffset })
            }
        }

        if startIndex % 8 == 0 {
            availableOffsets.removeAll(where: { $0 == 15 || $0 == 6 || $0 == -17 || $0 == -10 })
        } else if (startIndex + 1) % 8 == 0 {
            availableOffsets.removeAll(where: { $0 == 17 || $0 == 10 || $0 == -15 || $0 == -6 })
        } else if startIndex % 8 == 1 {
            availableOffsets.removeAll(where: { $0 == 6 || $0 == -10 })
        } else if startIndex % 8 == 6 {
            availableOffsets.removeAll(where: { $0 == 10 || $0 == -6 })
        }

        for availableOffset in availableOffsets {
            if pieceColor != Piece.pieceColor(from: squares[safe: startIndex + availableOffset] ?? 0) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + availableOffset))
            }
        }

        return moves
    }

    private func getAvailableKingMoves(at startIndex: Int, for piece: Int) -> [Move] {
        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]
        var directionOffsets = self.directionOffsets
        let pieceColor = Piece.pieceColor(from: piece)

        if startIndex % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == -9 || $0 == -1 || $0 == 7 })
        } else if (startIndex + 1) % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == 9 || $0 == 1 || $0 == -7 })
        }

        for directionOffset in directionOffsets {
            if (startIndex + directionOffset >= 0 && startIndex + directionOffset < 64)
                && pieceColor != Piece.pieceColor(from: squares[safe: startIndex + directionOffset] ?? 0) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + directionOffset))
            }
        }

        // TODO: handle pseudo legal moves
        // TODO: handle castle scenario

        return moves
    }

    private func getAvailablePawnMoves(at startIndex: Int, for piece: Int) -> [Move] {
        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]
        let pieceColor = Piece.pieceColor(from: piece)

        var oneStepForward = 8
        var twoStepForward = 16
        var attackSteps = [7, 9]

        // MARK: Define direction
        if pieceColor == Piece.black {
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
        if moves.count > 1 && squares[startIndex + twoStepForward] == 0 && (
            (pieceColor == Piece.white && (startIndex >= 8 && startIndex < 16))
                || (pieceColor == Piece.black && (startIndex >= 48 && startIndex < 56))
        ) {
            moves.append(.init(startSquare: startIndex, targetSquare: startIndex + twoStepForward))
        }

        if pieceColor == Piece.white {
            if startIndex % 8 == 0 {
                attackSteps.removeAll(where: { abs($0) == 7 })
            } else if (startIndex + 1) % 8 == 0 {
                attackSteps.removeAll(where: { abs($0) == 9 })
            }
        } else if pieceColor == Piece.black {
            if startIndex % 8 == 0 {
                attackSteps.removeAll(where: { abs($0) == 9 })
            } else if (startIndex + 1) % 8 == 0 {
                attackSteps.removeAll(where: { abs($0) == 7 })
            }
        }

        for attackStep in attackSteps {
            if let pieceAtTargetSquare = squares[safe: startIndex + attackStep],
               let pieceColorAtTargetSquare = Piece.pieceColor(from: pieceAtTargetSquare),
               pieceColorAtTargetSquare != Piece.pieceColor(from: piece) {
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

        if fenString.contains(where: { $0 == "w" }) {
           self.sideToMove = Piece.white
        } else if fenString.contains(where: { $0 == "b" }) {
           self.sideToMove = Piece.black
        }

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
        let startOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 0 : 56
        let endOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 7 : 63

        return move.targetSquare >= startOfPromotionZone && move.targetSquare <= endOfPromotionZone
    }
}
