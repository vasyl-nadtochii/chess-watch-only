//
//  GameEngine+AI.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 28.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: AI-related logic

    internal func makeComputerMove() {
        let legalMoves = getAllAvailableMoves(
            forSide: opponentToPlayerSide,
            shouldIncludeInitialMove: false,
            shouldValidateMoves: true
        )
        var predictedMoves = aiEngine.predictMoves(
            legalMoves: legalMoves,
            piecesMap: getPiecesMap()
        )
        predictedMoves = predictedMoves?.filter { predictedMove in
            return legalMoves.contains(where: { $0.toSANMoveString() == predictedMove })
        }
        if let predictedMoves, !predictedMoves.isEmpty,
           let bestMoveString = predictedMoves.first,
           let bestMove = bestMoveString.fromSANString(),
           let piece = board[bestMove.startSquare] {
            if !makeMove(move: bestMove, piece: piece) {
                print("Computer was unable to make move")
            }
        } else {
            // if model can't pick moves, pick random
            print("INFO: Computer picks random move")
            if let randomMove = legalMoves.randomElement(), let piece = board[randomMove.startSquare] {
                if !makeMove(move: randomMove, piece: piece) {
                    print("Computer was unable to make move")
                }
            } else {
                print("Computer can't pick random move")
            }
        }
    }
}
