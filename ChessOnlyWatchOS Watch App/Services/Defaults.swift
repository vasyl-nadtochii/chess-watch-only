//
//  Defaults.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class Defaults {

    private let playerSideKey: String = "playerSideKey"
    var playerSide: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: playerSideKey)
            if value == 0 {
                return Piece.white
            }
            return value
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: playerSideKey)
        }
    }
}
