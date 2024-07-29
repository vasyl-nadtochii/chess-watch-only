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
}
