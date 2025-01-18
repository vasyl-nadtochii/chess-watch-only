//
//  GameEngine+FENLoader.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 25.07.2024.
//

import Foundation

extension GameEngine {

    // MARK: FEN String Processor
    internal func loadPositionsFromFEN(_ fenString: String) {
        let pieceTypeFromSymbol: [Character: Int] = [
            "k": Piece.king,
            "p": Piece.pawn,
            "n": Piece.knight,
            "b": Piece.bishop,
            "r": Piece.rook,
            "q": Piece.queen
        ]

        let splitFENString = fenString.split(separator: " ")

        guard let fenBoard = splitFENString[safe: 0] else {
            print("Error: wrong format of FEN string -> \(fenString)")
            return
        }
        var file = 0
        var rank = 7

        let activeSide = splitFENString[safe: 1]
        if activeSide?.count == 1 {
            if activeSide == "w" {
                self.sideToMove = Piece.white
            } else if activeSide == "b" {
                self.sideToMove = Piece.black
            }
        }

        if let castlingRights = splitFENString[safe: 2] {
            if castlingRights == "-" {
                self.castlingRights = [
                    Piece.white: [
                        .kingSide: false,
                        .queenSide: false
                    ],
                    Piece.black: [
                        .kingSide: false,
                        .queenSide: false
                    ]
                ]
            } else {
                for key in castlingRights {
                    if let valueFromKey = CastlingSide.fromFENStringKey(fenStringKey: String(key)) {
                        self.castlingRights[key.isLowercase ? Piece.black : Piece.white]?[valueFromKey] = true
                    }
                }
            }
        }

        for symbol in fenBoard {
            if symbol == "/" {
                file = 0
                rank -= 1
            } else {
                if symbol.isNumber, let number = symbol.wholeNumberValue {
                    file += number
                } else {
                    let pieceColor = symbol.isUppercase ? Piece.white : Piece.black
                    let pieceType = pieceTypeFromSymbol[Character(symbol.lowercased())]
                    board[rank * 8 + file] = (pieceType ?? 0) | pieceColor
                    file += 1
                }
            }
        }
    }

    internal func updateSavedGame() {
        defaults.savedGameFENString = boardToFEN()
    }

    private func boardToFEN() -> String {
        guard (0...63).contains(board.keys.min() ?? 0),
              (0...63).contains(board.keys.max() ?? 0) else {
            return "Invalid board positions"
        }

        var fenRows: [String] = []

        for row in 0..<8 {
            var rowFEN = ""
            var emptySquares = 0

            for col in 0..<8 {
                let position = row * 8 + col
                if let pieceInt = board[position] {
                    if emptySquares > 0 {
                        rowFEN += "\(emptySquares)"
                        emptySquares = 0
                    }
                    var pieceString = Piece.symbolFromPiece(Piece.pieceType(from: pieceInt) ?? 0)
                    if Piece.pieceColor(from: pieceInt) == Piece.white {
                        pieceString = pieceString.uppercased()
                    }
                    rowFEN += pieceString
                } else {
                    emptySquares += 1
                }
            }

            if emptySquares > 0 {
                rowFEN += "\(emptySquares)"
            }

            fenRows.append(rowFEN)
        }

        return fenRows.reversed().joined(separator: "/")
    }
}
