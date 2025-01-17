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
        let kingIsUnderAttack = checkIfPieceIsUnderAttack(pieceSide: pieceColor, piecePosition: kingPosition)

        board[move.startSquare] = piece
        board[move.targetSquare] = pieceAtTargetSquare
        if let pieceTookByEnPassantMoveUnwrapped = pieceTookByEnPassantMove, let enPassantSquareIndex = enPassantSquareIndex {
            board[enPassantSquareIndex] = pieceTookByEnPassantMoveUnwrapped
        }

        return !kingIsUnderAttack
    }

    internal func checkIfPieceIsUnderAttack(pieceSide: Int, piecePosition: Int) -> Bool {
        guard pieceSide == Piece.white || pieceSide == Piece.black else {
            print("Invalid side passed")
            return false
        }

        guard !checkIfPieceIsAttackedByPawn(pieceSide: pieceSide, piecePosition: piecePosition) else {
            return true
        }
        guard !checkIfPieceIsAttackedByKnight(pieceSide: pieceSide, piecePosition: piecePosition) else {
            return true
        }
        guard !checkIfPieceIsAttackedBySlidingPiece(pieceSide: pieceSide, piecePosition: piecePosition) else {
            return true
        }

        return false
    }

    private func checkIfPieceIsAttackedByPawn(pieceSide: Int, piecePosition: Int) -> Bool {
        let oppositeColorToPiece = pieceSide == Piece.white ? Piece.black : Piece.white

        var possiblePawnOffsets = [7, 9]

        if pieceSide == Piece.white {
            if piecePosition % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 7 })
            } else if (piecePosition + 1) % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 9 })
            }
        } else if piecePosition == Piece.black {
            if piecePosition % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 9 })
            } else if (piecePosition + 1) % 8 == 0 {
                possiblePawnOffsets.removeAll(where: { abs($0) == 7 })
            }
        }

        if pieceSide == Piece.black {
            possiblePawnOffsets = possiblePawnOffsets.map({ $0 * -1 })
        }

        let possiblePawnPositions = possiblePawnOffsets.map { $0 + piecePosition }

        return possiblePawnPositions.contains(where: { board[$0] == Piece.pawn | oppositeColorToPiece })
    }

    private func checkIfPieceIsAttackedByKnight(pieceSide: Int, piecePosition: Int) -> Bool {
        let oppositeColorToPiece = pieceSide == Piece.white ? Piece.black : Piece.white
        var possibleKnightOffsets = [15, 17, -15, -17, 10, 6, -10, -6]

        for availableOffset in possibleKnightOffsets {
            if piecePosition + availableOffset < 0 || piecePosition + availableOffset >= 64 {
                possibleKnightOffsets.removeAll(where: { $0 == availableOffset })
            }
        }

        if piecePosition % 8 == 0 {
            possibleKnightOffsets.removeAll(where: { $0 == 15 || $0 == 6 || $0 == -17 || $0 == -10 })
        } else if (piecePosition + 1) % 8 == 0 {
            possibleKnightOffsets.removeAll(where: { $0 == 17 || $0 == 10 || $0 == -15 || $0 == -6 })
        } else if piecePosition % 8 == 1 {
            possibleKnightOffsets.removeAll(where: { $0 == 6 || $0 == -10 })
        } else if piecePosition % 8 == 6 {
            possibleKnightOffsets.removeAll(where: { $0 == 10 || $0 == -6 })
        }

        let possibleKnightPositions = possibleKnightOffsets.map { $0 + piecePosition }

        return possibleKnightPositions.contains(where: { board[$0] == Piece.knight | oppositeColorToPiece })
    }

    private func checkIfPieceIsAttackedBySlidingPiece(pieceSide: Int, piecePosition: Int) -> Bool {
        let oppositeColorToPiece = pieceSide == Piece.white ? Piece.black : Piece.white

        let startDirectionIndex = 0
        let endDirectionIndex = 8

        for directionIndex in startDirectionIndex..<endDirectionIndex {
            for n in 0..<numberOfSquaresToEdge[piecePosition][directionIndex] {
                let targetSquareIndex = piecePosition + directionOffsets[directionIndex] * (n + 1)
                let pieceOnTargetSquare = board[targetSquareIndex] ?? 0

                if Piece.pieceColor(from: pieceOnTargetSquare) == pieceSide {
                    break
                } else if Piece.pieceColor(from: pieceOnTargetSquare) == oppositeColorToPiece {
                    if pieceOnTargetSquare == Piece.queen | oppositeColorToPiece {
                        return true
                    } else if (pieceOnTargetSquare == Piece.rook | oppositeColorToPiece) && directionIndex < 4 {
                        return true
                    } else if (pieceOnTargetSquare == Piece.bishop | oppositeColorToPiece) && directionIndex >= 4 {
                        return true
                    } else {
                        break
                    }
                }
            }
        }

        return false
    }

    internal func checkIfPieceIsAttackedByKing(pieceSide: Int, piecePosition: Int) -> Bool {
        let oppositeColorToPiece = pieceSide == Piece.white ? Piece.black : Piece.white
        guard let oppositeKingPosition = board.first(where: { $0.value == Piece.king | oppositeColorToPiece })?.key else {
            print("No king on the board?")
            return true
        }
        var possibleKingOffsets = [1, -1, -8, 8, 7, -7, 9, -9]

        if oppositeKingPosition % 8 == 0 {
            possibleKingOffsets.removeAll(where: {
                $0 == -9 || $0 == -1 || $0 == 7
            })
        } else if (oppositeKingPosition + 1) % 8 == 0 {
            possibleKingOffsets.removeAll(where: {
                $0 == 9 || $0 == 1 || $0 == -7
            })
        }

        if oppositeKingPosition < 8 {
            possibleKingOffsets.removeAll(where: {
                $0 == -8
            })
        } else if oppositeKingPosition >= 56 {
            possibleKingOffsets.removeAll(where: {
                $0 == 8
            })
        }

        for possibleKingOffset in possibleKingOffsets {
            if oppositeKingPosition + possibleKingOffset == piecePosition {
                return true
            }
        }

        return false
    }
}
