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

        guard let kingPosition = board.keys.first(where: { board[$0] == Piece.king | pieceColor }) else {
            print("Error: is there no king at board?")
            return false
        }
        let kingIsUnderAttack = checkIfKingIsUnderAttack(kingSide: pieceColor, kingPosition: kingPosition)

        board[move.startSquare] = piece
        board[move.targetSquare] = pieceAtTargetSquare
        if let pieceTookByEnPassantMoveUnwrapped = pieceTookByEnPassantMove, let enPassantSquareIndex = enPassantSquareIndex {
            board[enPassantSquareIndex] = pieceTookByEnPassantMoveUnwrapped
        }

        return !kingIsUnderAttack
    }

    internal func checkIfKingIsUnderAttack(kingSide: Int, kingPosition: Int) -> Bool {
        guard kingSide == Piece.white || kingSide == Piece.black else {
            print("Invalid side passed")
            return false
        }
        guard board[kingPosition] == Piece.king | kingSide else {
            print("Invalid king position passed for \(kingSide == Piece.white ? "White" : "Black") side")
            return false
        }

        guard !checkIfKingIsAttackedByPawn(kingSide: kingSide, kingPosition: kingPosition) else {
            return true
        }
        guard !checkIfKingIsAttackedByKnight(kingSide: kingSide, kingPosition: kingPosition) else {
            return true
        }
        guard !checkIfKingIsAttackedBySlidingPiece(kingSide: kingSide, kingPosition: kingPosition) else {
            return true
        }

        return false
    }

    private func checkIfKingIsAttackedByPawn(kingSide: Int, kingPosition: Int) -> Bool {
        let oppositeColorToKing = kingSide == Piece.white ? Piece.black : Piece.white

        var possiblePawnOffsets = [7, 9]

        if kingPosition == Piece.white {
            if kingPosition % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 7 })
            } else if (kingPosition + 1) % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 9 })
            }
        } else if kingPosition == Piece.black {
            if kingPosition % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 9 })
            } else if (kingPosition + 1) % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 7 })
            }
        }

        if kingPosition == Piece.black {
            possiblePawnOffsets = possiblePawnOffsets.map({ $0 * -1 })
        }

        let possiblePawnPositions = possiblePawnOffsets.map { $0 + kingPosition }

        return possiblePawnPositions.contains(where: { board[$0] == Piece.pawn | oppositeColorToKing })
    }

    private func checkIfKingIsAttackedByKnight(kingSide: Int, kingPosition: Int) -> Bool {
        let oppositeColorToKing = kingSide == Piece.white ? Piece.black : Piece.white
        var possibleKnightOffsets = [15, 17, -15, -17, 10, 6, -10, -6]

        for availableOffset in possibleKnightOffsets {
            if kingPosition + availableOffset < 0 || kingPosition + availableOffset >= 64 {
                possibleKnightOffsets.removeAll(where: { $0 == availableOffset })
            }
        }

        if kingPosition % 8 == 0 {
            possibleKnightOffsets.removeAll(where: { $0 == 15 || $0 == 6 || $0 == -17 || $0 == -10 })
        } else if (kingPosition + 1) % 8 == 0 {
            possibleKnightOffsets.removeAll(where: { $0 == 17 || $0 == 10 || $0 == -15 || $0 == -6 })
        } else if kingPosition % 8 == 1 {
            possibleKnightOffsets.removeAll(where: { $0 == 6 || $0 == -10 })
        } else if kingPosition % 8 == 6 {
            possibleKnightOffsets.removeAll(where: { $0 == 10 || $0 == -6 })
        }

        let possibleKnightPositions = possibleKnightOffsets.map { $0 + kingPosition }

        return possibleKnightPositions.contains(where: { board[$0] == Piece.knight | oppositeColorToKing })
    }

    private func checkIfKingIsAttackedBySlidingPiece(kingSide: Int, kingPosition: Int) -> Bool {
        let oppositeColorToKing = kingSide == Piece.white ? Piece.black : Piece.white

        let startDirectionIndex = 0
        let endDirectionIndex = 8

        for directionIndex in startDirectionIndex..<endDirectionIndex {
            for n in 0..<numberOfSquaresToEdge[kingPosition][directionIndex] {
                let targetSquareIndex = kingPosition + directionOffsets[directionIndex] * (n + 1)
                let pieceOnTargetSquare = board[targetSquareIndex] ?? 0

                if Piece.pieceColor(from: pieceOnTargetSquare) == kingPosition {
                    break
                } else if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToKing {
                    if pieceOnTargetSquare == Piece.queen | oppositeColorToKing {
                        return true
                    } else if (pieceOnTargetSquare == Piece.rook | oppositeColorToKing) && directionIndex < 4 {
                        return true
                    } else if (pieceOnTargetSquare == Piece.bishop | oppositeColorToKing) && directionIndex >= 4 {
                        return true
                    } else {
                        break
                    }
                }
            }
        }

        return false
    }
}
