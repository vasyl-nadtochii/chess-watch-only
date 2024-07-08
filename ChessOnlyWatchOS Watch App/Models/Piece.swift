//
//  Piece.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class Piece {

    static let king = 1
    static let pawn = 2
    static let knight = 3
    static let bishop = 4
    static let rook = 5
    static let queen = 6

    static let white = 8
    static let black = 16
}

extension Piece {

    static func iconNameFromInt(_ intValue: Int) -> String? {
        var binaryRepresentation = String(intValue, radix: 2)

        guard binaryRepresentation.count >= 4 else { return nil }

        if binaryRepresentation.count == 4 {
            binaryRepresentation = "0\(binaryRepresentation)"
        }

        var color = String()
        var type = String()

        let prefix = binaryRepresentation.prefix(2)
        if prefix == "00" {
            return nil
        } else if prefix == "01" {
            color = "w"
        } else if prefix == "10" {
            color = "b"
        }

        let suffix = binaryRepresentation.suffix(3)
        if suffix == "000" {
            return nil
        } else if suffix == "001" {
            type = "king"
        } else if suffix == "010" {
            type = "pawn"
        } else if suffix == "011" {
            type = "knight"
        } else if suffix == "100" {
            type = "bishop"
        } else if suffix == "101" {
            type = "rook"
        } else if suffix == "110" {
            type = "queen"
        }

        return "\(type)-\(color)"
    }

    static func pieceColor(from piece: Int) -> Int? {
        var binaryRepresentation = String(piece, radix: 2)

        guard binaryRepresentation.count >= 4 else { return nil }
        if binaryRepresentation.count == 4 {
            binaryRepresentation = "0\(binaryRepresentation)"
        }

        let prefix = binaryRepresentation.prefix(2)
        if prefix == "00" {
            return nil
        } else if prefix == "01" {
            return Piece.white
        } else if prefix == "10" {
            return Piece.black
        }
        return nil
    }

    static func pieceType(from piece: Int) -> Int? {
        var binaryRepresentation = String(piece, radix: 2)

        guard binaryRepresentation.count >= 4 else { return nil }
        if binaryRepresentation.count == 4 {
            binaryRepresentation = "0\(binaryRepresentation)"
        }

        let suffix = binaryRepresentation.suffix(3)
        if suffix == "000" {
            return nil
        } else if suffix == "001" {
            return Piece.king
        } else if suffix == "010" {
            return Piece.pawn
        } else if suffix == "011" {
            return Piece.knight
        } else if suffix == "100" {
            return Piece.bishop
        } else if suffix == "101" {
            return Piece.rook
        } else if suffix == "110" {
            return Piece.queen
        }
        return nil
    }

    static func pieceName(fromType pieceType: Int) -> String {
        switch pieceType {
        case Piece.pawn:
            return "Pawn"
        case Piece.king:
            return "King"
        case Piece.queen:
            return "Queen"
        case Piece.bishop:
            return "Bishop"
        case Piece.knight:
            return "Knight"
        case Piece.rook:
            return "Rook"
        default:
            return String()
        }
    }

    static func isSlidingPiece(_ piece: Int) -> Bool {
        let slidingPieces = [Piece.bishop, Piece.rook, Piece.queen]
        return slidingPieces.contains(where: { $0 == pieceType(from: piece) })
    }

    static var pawnPromotionOptions: [Int] {
        return [ Piece.queen, Piece.rook, Piece.bishop, Piece.knight ]
    }
}
