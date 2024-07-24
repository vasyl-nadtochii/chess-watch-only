//
//  GameEngine+Moves.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Moves Handler
    func makeMove(move: Move, piece: Int) -> Bool {
        guard move.startSquare != move.targetSquare else { return false }
        guard sideToMove == Piece.pieceColor(from: piece) else {
            return false
        }

        var moveCopy = move
        moveCopy.pieceThatMoved = piece

        var capturedPiece = board[move.targetSquare] != nil
        if capturedPiece {
            moveCopy.capturedPiece = .init(piece: board[move.targetSquare] ?? 0, cellIndex: move.targetSquare)
        }

        let madeCastleMove = performCastleMoveIfNeed(piece: piece, move: move)
        let sidesWithRemovedCastlingRight = removeCastlingRightIfNeed(move: move, piece: piece)
        if !sidesWithRemovedCastlingRight.isEmpty {
            moveCopy.removedCastlingRightSides = sidesWithRemovedCastlingRight
        }

        board.removeValue(forKey: move.startSquare)
        board[move.targetSquare] = piece

        if let enPassantSquareIndex = enPassantSquareIndex,
           checkIfUserUsedEnPassantMove(enPassantSquareIndex: enPassantSquareIndex, move: move, piece: piece) {
            moveCopy.capturedPiece = .init(piece: board[enPassantSquareIndex] ?? 0, cellIndex: enPassantSquareIndex)
            board.removeValue(forKey: enPassantSquareIndex)
            capturedPiece = true
        }

        moveCopy.enPassantSquareIndex = enPassantSquareIndex
        self.enPassantSquareIndex = nil

        var playerSidePromotion = false

        if Piece.pieceType(from: piece) == Piece.pawn {
            if checkPawnPromotion(move: move, piece: piece) {
                if sideToMove == playerSide {
                    onResult?(.pawnShouldBePromoted(pawn: piece, pawnIndex: move.targetSquare))
                    playerSidePromotion = true
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

        if !playerSidePromotion {
            toggleSideToMove()
        }

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
        board[lastMove.startSquare] = pieceThatMoved
        board.removeValue(forKey: lastMove.targetSquare)

        if let capturedPiece = lastMove.capturedPiece {
            board[capturedPiece.cellIndex] = capturedPiece.piece
        }
        if let removedCastlingRightSides = lastMove.removedCastlingRightSides,
           let sideForWhichCastlingRightsRemoved = removedCastlingRightSides.keys.first,
           let sides = removedCastlingRightSides[sideForWhichCastlingRightsRemoved] {
            for side in sides {
                castlingRights[sideForWhichCastlingRightsRemoved]?[side] = true
            }
        }
        if lastMove.promotedPawn {
            board[lastMove.startSquare] = Piece.pawn | pieceColor
        }
        if let enPassantSquareIndex = lastMove.enPassantSquareIndex {
            self.enPassantSquareIndex = enPassantSquareIndex
        }

        movesHistory.removeLast()
        toggleSideToMove()
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

    internal func getAllAvailableAttackMoves(forSide colorToPickMoves: Int) -> [Move] {
        var piecesToPickMovesFor: [(startIndex: Int, piece: Int)] = []
        for index in board.keys {
            if let pieceAtIndex = board[index],
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

    internal func getAllAvailableMoves(forSide colorToPickMovesFor: Int?) -> [Move] {
        var piecesToPickMovesFor: [(startIndex: Int, piece: Int)] = []

        for index in board.keys {
            if let pieceAtIndex = board[index] {
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
}
