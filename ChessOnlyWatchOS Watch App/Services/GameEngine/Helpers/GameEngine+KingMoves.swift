//
//  GameEngine+KingMoves.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: King Moves Handler
    internal func getAvailableKingMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool = false) -> [Move] {
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

        for directionOffset in directionOffsets {
            if (startIndex + directionOffset >= 0 && startIndex + directionOffset < 64)
                && pieceColor != Piece.pieceColor(from: board[startIndex + directionOffset] ?? 0)
                && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex + directionOffset)) {
                moves.append(.init(startSquare: startIndex, targetSquare: startIndex + directionOffset))
            }
        }

        // MARK: Handle castle scenario
        if !onlyAttackMoves && !checkIfKingIsUnderAttack(kingSide: pieceColor, kingPosition: startIndex) {
            let castlingRightsForSelectedColor = castlingRights[pieceColor]
            if castlingRightsForSelectedColor?[.kingSide] == true {
                if board[startIndex + 1] == nil && board[startIndex + 2] == nil
                    && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex + 1))
                    && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex + 2)) {
                    moves.append(.init(startSquare: startIndex, targetSquare: startIndex + 2))
                }
            }
            if castlingRightsForSelectedColor?[.queenSide] == true {
                if board[startIndex - 1] == nil && board[startIndex - 2] == nil && board[startIndex - 3] == nil
                    && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex - 1))
                    && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex - 2))
                    && checkIfMoveIsValid(piece: piece, move: .init(startSquare: startIndex, targetSquare: startIndex - 3)) {
                    moves.append(.init(startSquare: startIndex, targetSquare: startIndex - 2))
                }
            }
        }

        return moves
    }
}
