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
        
        case madePlainMove
        case capturedPiece
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
    private var enPassantSquareIndex: Int?

    var opponentToPlayerSide: Int {
        return (playerSide == Piece.white) ? Piece.black : Piece.white
    }

    // initial position
    // let fenString = Constants.initialChessPosition
    let fenString = "8/n4Q1B/2N5/7B/8/R3k3/R4P2/8" // just for test

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.squares = Array(repeating: 0, count: 64)
        self.playerSide = defaults.playerSide
        self.sideToMove = defaults.playerSide

        loadPositionsFromFEN(fenString)
        precomputedMoveData()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.playerSide = defaults.playerSide
            self.onResult?(.playerSideUpdated)
        }
    }

    func getAvailableMoves(at startIndex: Int?, for piece: Int?, onlyAttackMoves: Bool = false) -> [Move] {
        guard let selectedCellIndex = startIndex,
            let pieceAtCell = piece,
            let selectedPieceType = Piece.pieceType(from: pieceAtCell)
        else { return [] }

        switch selectedPieceType {
        case Piece.king:
            return getAvailableKingMoves(at: selectedCellIndex, for: pieceAtCell)
        case Piece.pawn:
            return getAvailablePawnMoves(
                at: selectedCellIndex,
                for: pieceAtCell,
                onlyAttackMoves: onlyAttackMoves
            )
        case Piece.bishop, Piece.queen, Piece.rook:
            return getAvailableSlidingMoves(
                at: selectedCellIndex,
                for: pieceAtCell,
                onlyAttackMoves: onlyAttackMoves
            )
        case Piece.knight:
            return getAvailableKnightMoves(at: selectedCellIndex, for: pieceAtCell)
        default:
            return []
        }
    }

    private func getAvailableSlidingMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool) -> [Move] {
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
                    if onlyAttackMoves {
                        moves.append(.init(startSquare: startIndex, targetSquare: targetSquareIndex))
                    }
                    break
                }
                
                moves.append(.init(startSquare: startIndex, targetSquare: targetSquareIndex))

                if !onlyAttackMoves {
                    if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToSelected
                        && Piece.pieceType(from: pieceOnTargetSquare) != Piece.king {
                        break
                    }
                } else {
                    if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToSelected {
                        break
                    }
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
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white

        if startIndex % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == -9 || $0 == -1 || $0 == 7 })
        } else if (startIndex + 1) % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == 9 || $0 == 1 || $0 == -7 })
        }
        
        let allAttackMovesForOppositeSide = getAllAvailableAttackMoves(forSide: oppositeColorToPiece)

        for directionOffset in directionOffsets {
            if (startIndex + directionOffset >= 0 && startIndex + directionOffset < 64)
                && pieceColor != Piece.pieceColor(from: squares[safe: startIndex + directionOffset] ?? 0)
                && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex + directionOffset }) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + directionOffset))
            }
        }
        
        // TODO: handle castle scenario

        return moves
    }

    private func getAvailablePawnMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool = false) -> [Move] {
        var moves: [Move] = [.init(startSquare: startIndex, targetSquare: startIndex)]
        let pieceColor = Piece.pieceColor(from: piece)
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white

        var oneStepForward = 8
        var twoStepForward = 16
        var attackSteps = [7, 9]
        
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

        // MARK: Define direction
        if pieceColor == Piece.black {
            oneStepForward *= -1
            twoStepForward *= -1
            attackSteps = attackSteps.map({ $0 * -1 })
        }
        
        guard !onlyAttackMoves else {
            return attackSteps.map({ Move(startSquare: startIndex, targetSquare: startIndex + $0) })
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

        // MARK: Handle attack steps
        for attackStep in attackSteps {
            if let pieceAtTargetSquare = squares[safe: startIndex + attackStep],
               let pieceColorAtTargetSquare = Piece.pieceColor(from: pieceAtTargetSquare),
               pieceColorAtTargetSquare != Piece.pieceColor(from: piece) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + attackStep))
            }
        }
        
        // MARK: Handle En Passant scenario
        if let enPassantSquareIndex = enPassantSquareIndex,
           (startIndex - 1 == enPassantSquareIndex || startIndex + 1 == enPassantSquareIndex),
           let pieceColorAtEnPassantSquareIndex = Piece.pieceColor(from: squares[enPassantSquareIndex]),
           pieceColorAtEnPassantSquareIndex == oppositeColorToPiece {
            var step: Int = 0
            if startIndex - 1 == enPassantSquareIndex {
                step = pieceColor == Piece.white ? 7 : -9
            } else if startIndex + 1 == enPassantSquareIndex {
                step = pieceColor == Piece.white ? 9 : -7
            }
            if squares[startIndex + step] == 0 {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + step))
            }
        }

        return moves
    }
    
    private func getAllAvailableAttackMoves(forSide colorToPickMoves: Int) -> [Move] {
        var piecesToPickMovesFor: [(startIndex: Int, piece: Int)] = []
        for index in 0..<squares.count {
            if let pieceAtIndex = squares[safe: index],
                pieceAtIndex != 0,
                Piece.pieceColor(from: pieceAtIndex) == colorToPickMoves {
                piecesToPickMovesFor.append((index, pieceAtIndex))
            }
        }
        
        var moves = [Move]()
        for piece in piecesToPickMovesFor {
            moves.append(contentsOf: getAvailableMoves(
                at: piece.startIndex,
                for: piece.piece,
                onlyAttackMoves: true
            ))
        }
        return Array(Set(moves))
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

        var capturedPiece = squares[move.targetSquare] != 0

        squares[move.startSquare] = 0
        squares[move.targetSquare] = piece
        
        if let enPassantSquareIndex = enPassantSquareIndex,
           checkIfUserUsedEnPassantMove(enPassantSquareIndex: enPassantSquareIndex, move: move, piece: piece) {
            squares[enPassantSquareIndex] = 0
            capturedPiece = true
        }
        
        self.enPassantSquareIndex = nil

        if Piece.pieceType(from: piece) == Piece.pawn {
            if checkPawnPromotion(move: move, piece: piece) {
                onResult?(.pawnShouldBePromoted(pawn: piece, pawnIndex: move.targetSquare))
                // TODO: also, when there is a timer implemented, we should pause it unless player finishes promotion
            } else if checkEnPassantStartScenario(move: move, piece: piece) {
                self.enPassantSquareIndex = move.targetSquare
            }
        }
        
        if capturedPiece {
            onResult?(.capturedPiece)
        } else {
            onResult?(.madePlainMove)
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
    
    // MARK: Pawn moves check

    private func checkPawnPromotion(move: Move, piece: Int) -> Bool {
        let startOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 0 : 56
        let endOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 7 : 63

        return move.targetSquare >= startOfPromotionZone && move.targetSquare <= endOfPromotionZone
    }
    
    private func checkEnPassantStartScenario(move: Move, piece: Int) -> Bool {
        guard Piece.pieceType(from: piece) == Piece.pawn else {
            return false
        }

        let pieceColor = Piece.pieceColor(from: piece)
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white

        if abs(move.targetSquare - move.startSquare) == 16 {
            let pieceOnLeft = squares[safe: move.targetSquare - 1] ?? 0
            let pieceOnRight = squares[safe: move.targetSquare + 1] ?? 0
            
            let pieceColorOnLeft = Piece.pieceColor(from: pieceOnLeft)
            let pieceColorOnRight = Piece.pieceColor(from: pieceOnRight)
            
            let pieceTypeOnLeft = Piece.pieceType(from: pieceOnLeft)
            let pieceTypeOnRight = Piece.pieceType(from: pieceOnRight)
            
            let conditionForLeftEdge = pieceTypeOnRight == Piece.pawn && pieceColorOnRight == oppositeColorToPiece
            let conditionForRightEdge = pieceTypeOnLeft == Piece.pawn && pieceColorOnLeft == oppositeColorToPiece
            
            if move.startSquare % 8 == 0 {
                return conditionForLeftEdge
            } else if (move.startSquare + 1) % 8 == 0 {
                return conditionForRightEdge
            }
            
            return conditionForLeftEdge || conditionForRightEdge
        }

        return false
    }
    
    private func checkIfUserUsedEnPassantMove(enPassantSquareIndex: Int, move: Move, piece: Int) -> Bool {
        let pieceColor = Piece.pieceColor(from: piece)
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white
        guard Piece.pieceType(from: piece) == Piece.pawn,
            let pieceAtEnPassantSquareIndex = squares[safe: enPassantSquareIndex],
            Piece.pieceType(from: pieceAtEnPassantSquareIndex) == Piece.pawn,
            Piece.pieceColor(from: pieceAtEnPassantSquareIndex) == oppositeColorToPiece
        else {
            return false
        }
        
        var step: Int = 0
        if move.startSquare - 1 == enPassantSquareIndex {
            step = pieceColor == Piece.white ? 7 : -9
        } else if move.startSquare + 1 == enPassantSquareIndex {
            step = pieceColor == Piece.white ? 9 : -7
        }
        
        return move.targetSquare == (move.startSquare + step)
    }
}
