//
//  Move.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 08.07.2024.
//

import Foundation

struct Move: Hashable, Identifiable {

    struct CapturedPiece: Hashable {
        let piece: Int
        let cellIndex: Int
    }

    let id: String = UUID().uuidString
    let startSquare: Int
    let targetSquare: Int

    var pieceThatMoved: Int?
    var enPassantSquareIndex: Int?
    var promotedPawn: Bool = false
    var removedCastlingRightSides: [Int: [CastlingSide]]?
    var capturedPiece: CapturedPiece?
}
