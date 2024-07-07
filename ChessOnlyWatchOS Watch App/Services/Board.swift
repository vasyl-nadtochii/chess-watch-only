//
//  Board.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class Board {

    var squares: [Int]
    var playerSide: Int

    // initial position
    let fenString = Constants.initialChessPosition
    // let fenString = "8/4R1PB/2P1P1P1/8/3k2P1/2p5/Nnp2p1K/2b1r3 w - - 0 1" // just for test

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.squares = Array(repeating: 0, count: 64)
        self.playerSide = defaults.playerSide
        loadPositionsFromFEN(fenString)

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.playerSide = defaults.playerSide
        }
    }

    private func loadPositionsFromFEN(_ fenString: String) {
        let pieceTypeFromSymbol: [Character: Int] = [
            "k": Piece.king,
            "p": Piece.pawn,
            "n": Piece.knight,
            "b": Piece.bishop,
            "r": Piece.rook,
            "q": Piece.queen
        ]

        let fenBoard = fenString.split(separator: " ")[0]
        var file = 0
        var rank = 7

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
                    squares[rank * 8 + file] = (pieceType ?? 0) | pieceColor
                    file += 1
                }
            }
        }
    }
}
