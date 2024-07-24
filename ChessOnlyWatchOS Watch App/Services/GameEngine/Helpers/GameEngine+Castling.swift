//
//  GameEngine+Castling.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Castle moves handler
    internal func removeCastlingRightIfNeed(move: Move, piece: Int) -> [Int: [CastlingSide]] {
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
            && Piece.pieceColor(from: board[move.targetSquare] ?? 0) == oppositeColorToPiece {
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

    internal func performCastleMoveIfNeed(piece: Int, move: Move) -> Bool {
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
            let rookPiece = board[kingSideRookIndex]
            board.removeValue(forKey: kingSideRookIndex)
            board[kingSideRookIndex - 2] = rookPiece
            return true
        } else if move.targetSquare - move.startSquare == -2
            && castlingRights[pieceColor]?[.queenSide] == true {
            let rookPiece = board[queenSideRookIndex]
            board.removeValue(forKey: queenSideRookIndex)
            board[queenSideRookIndex + 3] = rookPiece
            return true
        }
        return false
    }
}
