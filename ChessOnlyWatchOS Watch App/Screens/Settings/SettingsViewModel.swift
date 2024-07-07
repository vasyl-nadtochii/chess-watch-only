//
//  SettingsViewModel.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

class SettingsViewModel: ObservableObject {

    @Published var playerSide: Int {
        didSet {
            defaults.playerSide = playerSide
            NotificationCenter.default.post(name: .playerSideUpdated, object: nil)
        }
    }
    var playerSideString: String {
        if playerSide == Piece.white {
            return "White"
        } else if playerSide == Piece.black {
            return "Black"
        } else {
            return String()
        }
    }

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.playerSide = defaults.playerSide
    }

    func togglePlayerSide() {
        if playerSide == Piece.white {
            playerSide = Piece.black
        } else {
            playerSide = Piece.white
        }
    }
}
