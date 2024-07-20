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

    var squares: [Int]
    var playerSide: Int
    var onResult: ((Result) -> Void)?
    var movesHistory: [Move] = []
    let gameMode: GameMode = .playerVsAI

    private var directionOffsets: [Int] = [8, -8, -1, 1, 7, -7, 9, -9]
    private var numberOfSquaresToEdge: [[Int]] = []
    private var enPassantSquareIndex: Int?
    private var castlingRights: [Int: [CastlingSide: Bool]]

    // initial position
    private let fenString = Constants.initialChessPosition
    // private let fenString = "6k1/2P5/8/8/8/8/6p1/2K5 w -" // just for test
    private let defaults: IDefaults

    init(defaults: IDefaults) {
        self.defaults = defaults
        self.squares = Array(repeating: 0, count: 64)
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

    func getAvailableMoves(at startIndex: Int?, for piece: Int?, onlyAttackMoves: Bool = false) -> [Move] {
        guard let selectedCellIndex = startIndex,
            let pieceAtCell = piece,
            let selectedPieceType = Piece.pieceType(from: pieceAtCell)
        else { return [] }

        switch selectedPieceType {
        case Piece.king:
            return getAvailableKingMoves(
                at: selectedCellIndex,
                for: pieceAtCell,
                onlyAttackMoves: onlyAttackMoves
            )
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
            return getAvailableKnightMoves(
                at: selectedCellIndex,
                for: pieceAtCell,
                onlyAttackMoves: onlyAttackMoves
            )
        default:
            return []
        }
    }

    private func getAvailableSlidingMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool) -> [Move] {
        let startDirectionIndex = (Piece.pieceType(from: piece) == Piece.bishop) ? 4 : 0
        let endDirectionIndex = (Piece.pieceType(from: piece) == Piece.rook) ? 4 : 8

        let pieceColorOfSelectedPiece = Piece.pieceColor(from: piece)
        let oppositeColorToSelected = pieceColorOfSelectedPiece == Piece.white ? Piece.black : Piece.white

        var moves: [Move] = onlyAttackMoves ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]

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
                    if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToSelected {
                        break
                    }
                } else {
                    if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToSelected
                        && Piece.pieceType(from: pieceOnTargetSquare) != Piece.king {
                        break
                    }
                }
            }
        }

        if onlyAttackMoves {
            return moves
        }
        return moves.filter({ checkIfMoveIsValid(piece: piece, move: $0) })
    }

    private func getAvailableKnightMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool = false) -> [Move] {
        var moves: [Move] = onlyAttackMoves ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]
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

        if onlyAttackMoves {
            return moves
        }
        return moves.filter({ checkIfMoveIsValid(piece: piece, move: $0) })
    }

    private func getAvailableKingMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool = false) -> [Move] {
        var moves: [Move] = onlyAttackMoves ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]
        var directionOffsets = self.directionOffsets

        guard let pieceColor = Piece.pieceColor(from: piece) else {
            print("Error: could not determine King color at index \(startIndex)")
            return moves
        }
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white

        if startIndex % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == -9 || $0 == -1 || $0 == 7 })
        } else if (startIndex + 1) % 8 == 0 {
            directionOffsets.removeAll(where: { $0 == 9 || $0 == 1 || $0 == -7 })
        }

        let allAttackMovesForOppositeSide: [Move] = onlyAttackMoves ? [] : getAllAvailableAttackMoves(forSide: oppositeColorToPiece)

        for directionOffset in directionOffsets {
            if (startIndex + directionOffset >= 0 && startIndex + directionOffset < 64)
                && pieceColor != Piece.pieceColor(from: squares[safe: startIndex + directionOffset] ?? 0)
                && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex + directionOffset }) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + directionOffset))
            }
        }

        // MARK: Handle castle scenario
        if !onlyAttackMoves && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex }) {
            let castlingRightsForSelectedColor = castlingRights[pieceColor]
            if castlingRightsForSelectedColor?[.kingSide] == true {
                if squares[startIndex + 1] == 0 && squares[startIndex + 2] == 0
                    && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex + 1 })
                    && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex + 2 }) {
                    moves.append(.init(startSquare: startIndex, targetSquare: startIndex + 2))
                }
            }
            if castlingRightsForSelectedColor?[.queenSide] == true {
                if squares[startIndex - 1] == 0 && squares[startIndex - 2] == 0 && squares[startIndex - 3] == 0
                    && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex - 1 })
                    && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex - 2 })
                    && !allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == startIndex - 3 }) {
                    moves.append(.init(startSquare: startIndex, targetSquare: startIndex - 2))
                }
            }
        }

        return moves
    }

    private func getAvailablePawnMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool = false) -> [Move] {
        var moves: [Move] = onlyAttackMoves ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]
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
        if moves.count > 1 && (
            (pieceColor == Piece.white && (startIndex >= 8 && startIndex < 16))
                || (pieceColor == Piece.black && (startIndex >= 48 && startIndex < 56))
        ) && squares[startIndex + twoStepForward] == 0 {
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
        
        if onlyAttackMoves {
            return moves
        }
        return moves.filter({ checkIfMoveIsValid(piece: piece, move: $0) })
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

    func getAllAvailableMoves(forSide colorToPickMovesFor: Int?) -> [Move] {
        var piecesToPickMovesFor: [(startIndex: Int, piece: Int)] = []

        for index in 0..<squares.count {
            if let pieceAtIndex = squares[safe: index],
                pieceAtIndex != 0 {
                if let colorToPickMovesForUnwrapped = colorToPickMovesFor,
                   Piece.pieceColor(from: pieceAtIndex) == colorToPickMovesForUnwrapped {
                    piecesToPickMovesFor.append((index, pieceAtIndex))
                } else if colorToPickMovesFor == nil {
                    piecesToPickMovesFor.append((index, pieceAtIndex))
                }
            }
        }

        var moves = [Move]()
        for piece in piecesToPickMovesFor {
            moves.append(contentsOf: getAvailableMoves(
                at: piece.startIndex,
                for: piece.piece,
                onlyAttackMoves: false
            ))
        }

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

        var moveCopy = move
        moveCopy.pieceThatMoved = piece

        var capturedPiece = squares[move.targetSquare] != 0
        if capturedPiece {
            moveCopy.capturedPiece = .init(piece: squares[move.targetSquare], cellIndex: move.targetSquare)
        }

        let madeCastleMove = performCastleMoveIfNeed(piece: piece, move: move)
        let sidesWithRemovedCastlingRight = removeCastlingRightIfNeed(move: move, piece: piece)
        if !sidesWithRemovedCastlingRight.isEmpty {
            moveCopy.removedCastlingRightSides = sidesWithRemovedCastlingRight
        }

        squares[move.startSquare] = 0
        squares[move.targetSquare] = piece

        if let enPassantSquareIndex = enPassantSquareIndex,
           checkIfUserUsedEnPassantMove(enPassantSquareIndex: enPassantSquareIndex, move: move, piece: piece) {
            squares[enPassantSquareIndex] = 0
            moveCopy.capturedPiece = .init(piece: squares[enPassantSquareIndex], cellIndex: enPassantSquareIndex)
            capturedPiece = true
        }
        
        moveCopy.enPassantSquareIndex = enPassantSquareIndex
        self.enPassantSquareIndex = nil

        if Piece.pieceType(from: piece) == Piece.pawn {
            if checkPawnPromotion(move: move, piece: piece) {
                if sideToMove == playerSide {
                    onResult?(.pawnShouldBePromoted(pawn: piece, pawnIndex: move.targetSquare))
                } else {
                    promoteComputerPawn(at: move.targetSquare)
                }
                moveCopy.promotedPawn = true
                // TODO: also, when there is a timer implemented, we should pause it unless player finishes promotion
            } else if checkEnPassantStartScenario(move: move, piece: piece) {
                self.enPassantSquareIndex = move.targetSquare
            }
        }

        if capturedPiece {
            onResult?(.capturedPiece)
        } else if madeCastleMove {
            onResult?(.madeCastleMove)
        } else {
            onResult?(.madePlainMove)
        }

        // TODO: Check for check/checkmate
        
        movesHistory.append(moveCopy)
        toggleSideToMove()

        return true
    }

    func unmakeMove() {
        guard let lastMove = movesHistory.last else {
            print("No moves recorded")
            return
        }
        guard let pieceThatMoved = lastMove.pieceThatMoved,
            let pieceColor = Piece.pieceColor(from: pieceThatMoved) else {
            print("No piece recorded for the move")
            return
        }
        squares[lastMove.startSquare] = pieceThatMoved
        squares[lastMove.targetSquare] = 0

        if let capturedPiece = lastMove.capturedPiece {
            squares[capturedPiece.cellIndex] = capturedPiece.piece
        }
        if let removedCastlingRightSides = lastMove.removedCastlingRightSides,
           let sideForWhichCastlingRightsRemoved = removedCastlingRightSides.keys.first,
           let sides = removedCastlingRightSides[sideForWhichCastlingRightsRemoved] {
            for side in sides {
                castlingRights[sideForWhichCastlingRightsRemoved]?[side] = true
            }
        }
        if lastMove.promotedPawn {
            squares[lastMove.startSquare] = Piece.pawn | pieceColor
        }
        if let enPassantSquareIndex = lastMove.enPassantSquareIndex {
            self.enPassantSquareIndex = enPassantSquareIndex
        }
        
        movesHistory.removeLast()
        toggleSideToMove()
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

        let splitFENString = fenString.split(separator: " ")

        guard let fenBoard = splitFENString[safe: 0] else {
            print("Error: wrong format of FEN string -> \(fenString)")
            return
        }
        var file = 0
        var rank = 7

        let activeSide = splitFENString[safe: 1]
        if activeSide?.count == 1 {
            if activeSide == "w" {
                self.sideToMove = Piece.white
            } else if activeSide == "b" {
                self.sideToMove = Piece.black
            }
        }

        if let castlingRights = splitFENString[safe: 2] { 
            if castlingRights == "-" {
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
            } else {
                for key in castlingRights {
                    if let valueFromKey = CastlingSide.fromFENStringKey(fenStringKey: String(key)) {
                        self.castlingRights[key.isLowercase ? Piece.black : Piece.white]?[valueFromKey] = true
                    }
                }
            }
        }

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
        if sideToMove == opponentToPlayerSide && gameMode == .playerVsAI {
            makeComputerMove()
        }
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

    // MARK: Castle moves handlers

    private func removeCastlingRightIfNeed(move: Move, piece: Int) -> [Int: [CastlingSide]] {
        guard let pieceType = Piece.pieceType(from: piece),
            let pieceColor = Piece.pieceColor(from: piece)
        else {
            return [:]
        }

        let moveStartIndex = move.startSquare

        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white
        let queenSideRookStartMoveIndex = pieceColor == Piece.white ? 0 : 56
        let kingSideRookStartMoveIndex = pieceColor == Piece.white ? 7 : 63

        let queenSideRookStartMoveIndexForOppositeSide = oppositeColorToPiece == Piece.white ? 0 : 56
        let kingSideRookStartMoveIndexForOppositeSide = oppositeColorToPiece == Piece.white ? 7 : 63

        if (move.targetSquare == queenSideRookStartMoveIndexForOppositeSide
            || move.targetSquare == kingSideRookStartMoveIndexForOppositeSide)
            && Piece.pieceColor(from: squares[move.targetSquare]) == oppositeColorToPiece {
            // MARK: Handle scenario when someone takes rook of opposite side
            if move.targetSquare == queenSideRookStartMoveIndexForOppositeSide {
                castlingRights[oppositeColorToPiece]?[.queenSide] = false
                return [oppositeColorToPiece: [.queenSide]]
            } else if move.targetSquare == kingSideRookStartMoveIndexForOppositeSide {
                castlingRights[oppositeColorToPiece]?[.kingSide] = false
                return [oppositeColorToPiece: [.kingSide]]
            }
        } else {
            // MARK: Handle scenario when someone moves king/rook
            if pieceType == Piece.rook {
                if moveStartIndex == queenSideRookStartMoveIndex {
                    castlingRights[pieceColor]?[.queenSide] = false
                    return [pieceColor: [.queenSide]]
                } else if moveStartIndex == kingSideRookStartMoveIndex {
                    castlingRights[pieceColor]?[.kingSide] = false
                    return [pieceColor: [.kingSide]]
                }
            } else if pieceType == Piece.king {
                castlingRights[pieceColor]?[.queenSide] = false
                castlingRights[pieceColor]?[.kingSide] = false
                return [pieceColor: [.queenSide, .kingSide]]
            }
        }
        return [:]
    }

    private func performCastleMoveIfNeed(piece: Int, move: Move) -> Bool {
        guard let pieceType = Piece.pieceType(from: piece),
            let pieceColor = Piece.pieceColor(from: piece),
            pieceType == Piece.king
        else {
            return false
        }

        let queenSideRookIndex = pieceColor == Piece.white ? 0 : 56
        let kingSideRookIndex = pieceColor == Piece.white ? 7 : 63

        if move.targetSquare - move.startSquare == 2 
            && castlingRights[pieceColor]?[.kingSide] == true {
            let rookPiece = squares[kingSideRookIndex]
            squares[kingSideRookIndex] = 0
            squares[kingSideRookIndex - 2] = rookPiece
            return true
        } else if move.targetSquare - move.startSquare == -2
            && castlingRights[pieceColor]?[.queenSide] == true {
            let rookPiece = squares[queenSideRookIndex]
            squares[queenSideRookIndex] = 0
            squares[queenSideRookIndex + 3] = rookPiece
            return true
        }
        return false
    }

    // MARK: Legal moves check
    private func checkIfMoveIsValid(piece: Int, move: Move) -> Bool {
        guard let pieceColor = Piece.pieceColor(from: piece) else {
            print("Error: couldn't get piece color")
            return false
        }
        let oppositeColor = pieceColor == Piece.white ? Piece.black : Piece.white

        if move.startSquare == move.targetSquare {
            return true
        }

        squares[move.startSquare] = 0

        let pieceAtTargetSquare = squares[move.targetSquare]
        squares[move.targetSquare] = piece

        var pieceTookByEnPassantMove: Int?

        if let enPassantSquareIndex = enPassantSquareIndex, Piece.pieceType(from: piece) == Piece.pawn {
            let expectedEnPassantTargetSquare = enPassantSquareIndex + (pieceColor == Piece.white ? 8 : -8)
            if move.targetSquare == expectedEnPassantTargetSquare {
                pieceTookByEnPassantMove = squares[enPassantSquareIndex]
                squares[enPassantSquareIndex] = 0
            }
        }

        let allAttackMovesForOppositeSide = getAllAvailableAttackMoves(forSide: oppositeColor)
        guard let kingPosition = squares.firstIndex(where: { $0 == Piece.king | pieceColor }) else {
            print("Error: is there no king at board?")
            return false
        }

        squares[move.startSquare] = piece
        squares[move.targetSquare] = pieceAtTargetSquare
        if let pieceTookByEnPassantMoveUnwrapped = pieceTookByEnPassantMove, let enPassantSquareIndex = enPassantSquareIndex {
            squares[enPassantSquareIndex] = pieceTookByEnPassantMoveUnwrapped
        }

        if allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == kingPosition }) {
            return false
        }
        return true
    }

    // MARK: Computer

    private func makeComputerMove() {
        guard let move = chooseComputerMove() else {
            print("Computer doesn't have available moves to pick")
            return
        }
        let pieceThatComputerPicked = squares[move.startSquare]
        _ = makeMove(move: move, piece: pieceThatComputerPicked)
    }

    private func chooseComputerMove() -> Move? {
        let moves = getAllAvailableMoves(forSide: opponentToPlayerSide).filter({ $0.startSquare != $0.targetSquare })
        return moves.randomElement()
    }

    private func promoteComputerPawn(at index: Int) {
        let pieces = [Piece.queen, Piece.bishop, Piece.knight, Piece.rook]
        let promotionPiece = pieces.randomElement() ?? Piece.queen
        promotePawn(at: index, from: (opponentToPlayerSide | Piece.pawn), to: promotionPiece)
    }
}
