//
//  CastlingSide.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 18.07.2024.
//

import Foundation

enum CastlingSide: Hashable {
    case kingSide
    case queenSide

    static func fromFENStringKey(fenStringKey: String) -> CastlingSide? {
        if fenStringKey.lowercased() == "k" {
            return .kingSide
        } else if fenStringKey.lowercased() == "q" {
            return .queenSide
        }
        return nil
    }
}
