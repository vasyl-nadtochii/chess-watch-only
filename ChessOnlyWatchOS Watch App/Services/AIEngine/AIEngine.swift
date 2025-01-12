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
    func predictMoves(legalMoves: [Move], piecesMap: [[Int]]) -> [String]?
}

class AIEngineImpl: AIEngine {

    let model: chess_model_from_export?
    var indexesToMove: [Int: String] = [:]

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

                let pieceTypeModelSpecific = self.getModelSpecificPieceType(fromTypeDomain: pieceType) - 1
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

    func predictMoves(legalMoves: [Move], piecesMap: [[Int]]) -> [String]? {
        guard let matrix = prepareInputMatrix(legalMoves: legalMoves, piecesMap: piecesMap) else {
            print("Instead of input matrix got nil")
            return nil
        }
        do {
            let shape: [NSNumber] = [1, 13, 8, 8]
            let multiArray = try MLMultiArray(shape: shape, dataType: .float32)

            for (matrixIndex, subMatrix) in matrix.enumerated() {
                for rowIndex in 0...7 {
                    for columnIndex in 0...7 {
                        let index = [0, matrixIndex, rowIndex, columnIndex] as [NSNumber]
                        multiArray[index] = NSNumber(value: subMatrix[rowIndex][columnIndex])
                    }
                }
            }

            let input = chess_model_from_exportInput(x: multiArray)
            let prediction = try self.model?.prediction(input: input)

            if let probabilitiesRaw = prediction?.linear_1ShapedArray {
                let moveProbabilities: [Float32] = Array(probabilitiesRaw.scalars)

                let softmax = moveProbabilities.map { exp($0) }
                let sum = softmax.reduce(0, +)
                let softmaxed = softmax.map { $0 / sum }

                if indexesToMove.isEmpty {
                    guard let moveToInts = IntMoveConverter.moveToInt else {
                        print("Couldn't retrieve move to int table")
                        return nil
                    }
                    initializeIndexesToMove(movesToInts: moveToInts)
                }

                let sortedMoves = softmaxed
                    .enumerated()
                    .map { (element: $0.element, offset: $0.offset) }
                    .sorted(by: { $0.element > $1.element })
                    .compactMap { indexesToMove[$0.offset] }

                return sortedMoves
            } else {
                print("Prediction received, but no values are given")
                return nil
            }
        }
        catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }

    private func initializeIndexesToMove(movesToInts: [String: Int]) {
        for (move, index) in movesToInts {
            indexesToMove[index] = move
        }
    }
}

extension AIEngine {

    func getModelSpecificPieceType(fromTypeDomain pieceTypeDomain: Int) -> Int {
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
