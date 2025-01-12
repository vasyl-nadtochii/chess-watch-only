//
//  AIEngine.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation
import CoreML

protocol AIEngine {
    func prepareInputMatrix(legalMoves: [Move], piecesMap: [[Int]]) -> [[Array<Double>]]?
}

class AIEngineImpl: AIEngine {

    let model: chess_model_from_export?

    init() {
        let config = MLModelConfiguration()
        do {
            self.model = try .init(configuration: config)
        } catch {
            self.model = nil
            print("AI MODEL INIT ERROR: \(error.localizedDescription)")
        }
    }

    func prepareInputMatrix(legalMoves: [Move], piecesMap: [[Int]]) -> [[Array<Double>]]? {
        var matrix = Array(
            repeating: Array(
                repeating: Array(
                    repeating: 0.0,
                    count: 8
                ),
                count: 8
            ),
            count: 13
        )

        // MARK: Fill in pieces positions
        for rowIndex in 0..<piecesMap.count {
            let row = piecesMap[rowIndex]
            for columnIndex in 0..<row.count {
                let piece = row[columnIndex]

                if piece == 0 {
                    continue
                }
 
                guard let pieceType = Piece.pieceType(from: piece) else {
                    print("Error: could not retrieve piece type from \(piece) at row: \(rowIndex), column: \(columnIndex)")
                    return nil
                }
                let pieceColor = Piece.pieceColor(from: piece)

                let pieceTypeModelSpecific = self.getPieceType(fromTypeDomain: pieceType) - 1
                let pieceColorModelSpecific: Int = pieceColor == Piece.white ? 0 : 6

                matrix[pieceTypeModelSpecific + pieceColorModelSpecific][rowIndex][columnIndex] = 1.0
            }
        }

        // MARK: Fill in legal moves
        for move in legalMoves where move.startSquare != move.targetSquare {
            let targetSquare = move.targetSquare
            let rowTo = targetSquare / 8
            let columnTo = targetSquare % 8

            matrix[12][rowTo][columnTo] = 1
        }

        return matrix
    }
}

extension AIEngine {

    func getPieceType(fromTypeDomain pieceTypeDomain: Int) -> Int {
        switch pieceTypeDomain {
        case Piece.pawn:
            return 1
        case Piece.knight:
            return 2
        case Piece.bishop:
            return 3
        case Piece.rook:
            return 4
        case Piece.queen:
            return 5
        case Piece.king:
            return 6
        default:
            return 0
        }
    }
}
