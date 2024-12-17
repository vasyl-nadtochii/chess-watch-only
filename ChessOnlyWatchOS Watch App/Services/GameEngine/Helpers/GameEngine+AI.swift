//
//  GameEngine+AI.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 28.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: Computer

    internal func makeComputerMove() {
        guard let move = chooseComputerMove() else {
            print("Computer doesn't have available moves to pick")
            return
        }
        guard let pieceThatComputerPicked = board[move.startSquare] else {
            print("Computer picked empty cell")
            return
        }
        _ = makeMove(move: move, piece: pieceThatComputerPicked)
    }

    internal func chooseComputerMove() -> Move? {
        let moves = getAllAvailableMoves(forSide: opponentToPlayerSide).filter({ $0.startSquare != $0.targetSquare })
        return moves.randomElement()
    }

    internal func promoteComputerPawn(at index: Int) {
        let pieces = [Piece.queen, Piece.bishop, Piece.knight, Piece.rook]
        let promotionPiece = pieces.randomElement() ?? Piece.queen
        promotePawn(at: index, from: (opponentToPlayerSide | Piece.pawn), to: promotionPiece)
    }

    internal func evaluate() -> Int {
        let whiteEvaluation = countMaterial(forSide: Piece.white)
        let blackEvaluation = countMaterial(forSide: Piece.black)

        let evaluation = whiteEvaluation - blackEvaluation
        let perspective = (sideToMove == Piece.white) ? 1 : -1

        return evaluation * perspective
    }

    internal func countMaterial(forSide side: Int) -> Int {
        var material = 0
        material += board.values.filter({ $0 == Piece.pawn | side }).count * Piece.pawnValue
        material += board.values.filter({ $0 == Piece.knight | side }).count * Piece.knightValue
        material += board.values.filter({ $0 == Piece.bishop | side }).count * Piece.bishopValue
        material += board.values.filter({ $0 == Piece.rook | side }).count * Piece.rookValue
        material += board.values.filter({ $0 == Piece.queen | side }).count * Piece.queenValue
        return material
    }

    internal func search(depth: Int, alpha: Int, beta: Int) -> Int? {
        guard depth >= 0 else { return nil }
        if depth == 0 {
            return evaluate()
        }

        var alpha = 0

        let moves = getAllAvailableMoves(
            forSide: nil,
            shouldIncludeInitialMove: false,
            shouldValidateMoves: false
        )

        if moves.isEmpty {
            if playerIsChecked {
                return Int.min
            }
            return 0
        }

        for move in moves {
            guard let pieceAtMoveStartIndex = board[move.startSquare] else {
                print("Couldn't get piece at move start index for \(move.startSquare)")
                return nil
            }
            if makeMove(
                move: move,
                piece: pieceAtMoveStartIndex,
                shouldValidateMove: true
            ) {
                let evaluation = -(search(depth: depth - 1, alpha: -beta, beta: -alpha) ?? 0)
                unmakeMove()
                if evaluation >= beta {
                    return beta
                }
                alpha = max(alpha, evaluation)
            }
        }

        return alpha
    }

    internal func orderMoves(moves: [Move]) {
        for move in moves {
            var moveScoreGuess = 0
            guard let piece = board[move.startSquare], let pieceColor = Piece.pieceColor(from: piece) else {
                print("Error: Invalid move. No piece at start index")
                return
            }
            let movePieceType = Piece.pieceType(from: piece) ?? 0 // TODO: ???
            let capturePieceType = Piece.pieceType(from: board[move.targetSquare] ?? 0)

            if let capturePieceType = capturePieceType {
                moveScoreGuess = 10
                    * Piece.pieceValue(fromType: capturePieceType)
                    - Piece.pieceValue(fromType: movePieceType)
            }

            // TODO: check if move will promote pawn

            if checkIfPieceIsUnderAttack(pieceSide: pieceColor, piecePosition: move.targetSquare) {
                moveScoreGuess -= Piece.pieceValue(fromType: movePieceType)
            }
        }
    }
}
