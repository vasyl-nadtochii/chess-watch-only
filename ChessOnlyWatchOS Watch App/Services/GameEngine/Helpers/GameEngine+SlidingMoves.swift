//
//  GameEngine+SlidingMoves.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Sliding Moves Handler
    internal func getAvailableSlidingMoves(at startIndex: Int, for piece: Int, onlyAttackMoves: Bool) -> [Move] {
        let startDirectionIndex = (Piece.pieceType(from: piece) == Piece.bishop) ? 4 : 0
        let endDirectionIndex = (Piece.pieceType(from: piece) == Piece.rook) ? 4 : 8

        let pieceColorOfSelectedPiece = Piece.pieceColor(from: piece)
        let oppositeColorToSelected = pieceColorOfSelectedPiece == Piece.white ? Piece.black : Piece.white

        var moves: [Move] = onlyAttackMoves ? [] : [.init(startSquare: startIndex, targetSquare: startIndex)]

        for directionIndex in startDirectionIndex..<endDirectionIndex {
            for n in 0..<numberOfSquaresToEdge[startIndex][directionIndex] {
                let targetSquareIndex = startIndex + directionOffsets[directionIndex] * (n + 1)
                let pieceOnTargetSquare = board[targetSquareIndex] ?? 0

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
}
