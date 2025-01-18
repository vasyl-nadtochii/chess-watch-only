//
//  GameEngine+PawnMoves.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Pawn Moves Handler
    func promotePawn(at squareIndex: Int, from pawn: Int, to newPieceType: Int) {
        guard let pawnColor = Piece.pieceColor(from: pawn) else { return }
        board[squareIndex] = newPieceType | pawnColor
        if pawnColor == playerSide {
            updateSavedGame()
            toggleSideToMove()
            onResult?(.pawnPromoted)
        }
    }

    internal func getAvailablePawnMoves(
        at startIndex: Int,
        for piece: Int,
        onlyAttackMoves: Bool = false,
        shouldIncludeInitialMove: Bool = true,
        shouldValidateMoves: Bool = true
    ) -> [Move] {
        var moves: [Move] = (onlyAttackMoves || !shouldIncludeInitialMove) ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]
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
            && board[startIndex + oneStepForward] == nil {
            moves.append(.init(startSquare: startIndex, targetSquare: startIndex + oneStepForward))
        }

        // MARK: Handle two steps forward (initial move)
        if moves.count > (shouldIncludeInitialMove ? 1 : 0) && (
            (pieceColor == Piece.white && (startIndex >= 8 && startIndex < 16))
                || (pieceColor == Piece.black && (startIndex >= 48 && startIndex < 56))
        ) && board[startIndex + twoStepForward] == nil {
            moves.append(.init(startSquare: startIndex, targetSquare: startIndex + twoStepForward))
        }

        // MARK: Handle attack steps
        for attackStep in attackSteps {
            if let pieceAtTargetSquare = board[startIndex + attackStep],
               let pieceColorAtTargetSquare = Piece.pieceColor(from: pieceAtTargetSquare),
               pieceColorAtTargetSquare != Piece.pieceColor(from: piece) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + attackStep))
            }
        }

        // MARK: Handle En Passant scenario
        if let enPassantSquareIndex = enPassantSquareIndex,
           (startIndex - 1 == enPassantSquareIndex || startIndex + 1 == enPassantSquareIndex),
           let pieceAtEnPassantIndex = board[enPassantSquareIndex],
           let pieceColorAtEnPassantSquareIndex = Piece.pieceColor(from: pieceAtEnPassantIndex),
           pieceColorAtEnPassantSquareIndex == oppositeColorToPiece {
            var step: Int = 0
            if startIndex - 1 == enPassantSquareIndex {
                step = pieceColor == Piece.white ? 7 : -9
            } else if startIndex + 1 == enPassantSquareIndex {
                step = pieceColor == Piece.white ? 9 : -7
            }
            if board[startIndex + step] == nil {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + step))
            }
        }

        if onlyAttackMoves || !shouldValidateMoves {
            return moves
        }
        return moves.filter({ checkIfMoveIsValid(piece: piece, move: $0) })
    }

    internal func checkPawnPromotion(move: Move, piece: Int) -> Bool {
        let startOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 0 : 56
        let endOfPromotionZone = Piece.pieceColor(from: piece) == Piece.black ? 7 : 63

        return move.targetSquare >= startOfPromotionZone && move.targetSquare <= endOfPromotionZone
    }

    internal func checkEnPassantStartScenario(move: Move, piece: Int) -> Bool {
        guard Piece.pieceType(from: piece) == Piece.pawn else {
            return false
        }

        let pieceColor = Piece.pieceColor(from: piece)
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white

        if abs(move.targetSquare - move.startSquare) == 16 {
            let pieceOnLeft = board[move.targetSquare - 1] ?? 0
            let pieceOnRight = board[move.targetSquare + 1] ?? 0

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

    internal func checkIfUserUsedEnPassantMove(enPassantSquareIndex: Int, move: Move, piece: Int) -> Bool {
        let pieceColor = Piece.pieceColor(from: piece)
        let oppositeColorToPiece = pieceColor == Piece.white ? Piece.black : Piece.white
        guard Piece.pieceType(from: piece) == Piece.pawn,
            let pieceAtEnPassantSquareIndex = board[enPassantSquareIndex],
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
