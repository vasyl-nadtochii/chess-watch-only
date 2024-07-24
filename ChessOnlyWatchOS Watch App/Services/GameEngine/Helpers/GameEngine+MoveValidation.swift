//
//  GameEngine+MoveValidation.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Moves Validator
    internal func checkIfMoveIsValid(piece: Int, move: Move) -> Bool {
        guard let pieceColor = Piece.pieceColor(from: piece) else {
            print("Error: couldn't get piece color")
            return false
        }
        let oppositeColor = pieceColor == Piece.white ? Piece.black : Piece.white

        if move.startSquare == move.targetSquare {
            return true
        }

        board.removeValue(forKey: move.startSquare)

        let pieceAtTargetSquare = board[move.targetSquare]
        board[move.targetSquare] = piece

        var pieceTookByEnPassantMove: Int?

        if let enPassantSquareIndex = enPassantSquareIndex, Piece.pieceType(from: piece) == Piece.pawn {
            let expectedEnPassantTargetSquare = enPassantSquareIndex + (pieceColor == Piece.white ? 8 : -8)
            if move.targetSquare == expectedEnPassantTargetSquare {
                pieceTookByEnPassantMove = board[enPassantSquareIndex]
                board.removeValue(forKey: enPassantSquareIndex)
            }
        }

        let allAttackMovesForOppositeSide = getAllAvailableAttackMoves(forSide: oppositeColor)
        guard let kingPosition = board.keys.first(where: { board[$0] == Piece.king | pieceColor }) else {
            print("Error: is there no king at board?")
            return false
        }

        board[move.startSquare] = piece
        board[move.targetSquare] = pieceAtTargetSquare
        if let pieceTookByEnPassantMoveUnwrapped = pieceTookByEnPassantMove, let enPassantSquareIndex = enPassantSquareIndex {
            board[enPassantSquareIndex] = pieceTookByEnPassantMoveUnwrapped
        }

        if allAttackMovesForOppositeSide.contains(where: { $0.targetSquare == kingPosition }) {
            return false
        }
        return true
    }
}
