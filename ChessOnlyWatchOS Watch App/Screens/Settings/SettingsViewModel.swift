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

    @Published var boardColorTheme: BoardColorTheme {
        didSet {
            defaults.boardColorTheme = boardColorTheme
            NotificationCenter.default.post(name: .boardColorThemeUpdated, object: nil)
        }
    }
    
    @Published var soundEnabled: Bool {
        didSet {
            defaults.soundEnabled = soundEnabled
        }
    }

    @Published var woodenTableEnabled: Bool {
        didSet {
            defaults.woodenTableEnabled = woodenTableEnabled
            NotificationCenter.default.post(name: .woodenTableIsOnUpdated, object: nil)
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
        self.boardColorTheme = defaults.boardColorTheme
        self.soundEnabled = defaults.soundEnabled
        self.woodenTableEnabled = defaults.woodenTableEnabled
    }

    func togglePlayerSide() {
        if playerSide == Piece.white {
            playerSide = Piece.black
        } else {
            playerSide = Piece.white
        }
    }

    func changeBoardColorTheme() {
        let allThemes = BoardColorTheme.allCases
        guard let currentIndex = allThemes.firstIndex(of: self.boardColorTheme) else {
            return
        }

        if currentIndex == allThemes.count - 1 {
            self.boardColorTheme = allThemes[0]
        } else {
            self.boardColorTheme = allThemes[currentIndex + 1]
        }
    }
}
