//
//  GameEngine+KnightMoves.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Knight Moves Handler
    internal func getAvailableKnightMoves(
        at startIndex: Int,
        for piece: Int,
        onlyAttackMoves: Bool = false,
        shouldIncludeInitialMove: Bool = true,
        shouldValidateMoves: Bool = true
    ) -> [Move] {
        var moves: [Move] = (onlyAttackMoves || !shouldIncludeInitialMove) ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]
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
            if pieceColor != Piece.pieceColor(from: board[startIndex + availableOffset] ?? 0) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + availableOffset))
            }
        }

        if onlyAttackMoves || !shouldValidateMoves {
            return moves
        }
        return moves.filter({ checkIfMoveIsValid(piece: piece, move: $0) })
    }
}
