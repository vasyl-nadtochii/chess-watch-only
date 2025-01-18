//
//  Defaults.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation

protocol IDefaults {
    
    var playerSide: Int { get set }
    var boardColorTheme: BoardColorTheme { get set }
    var soundEnabled: Bool { get set }
    var woodenTableEnabled: Bool { get set }
    var savedGameFENString: String? { get set }
}

class Defaults: IDefaults {

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

    private let boardColorThemeKey: String = "appThemeKey"
    var boardColorTheme: BoardColorTheme {
        get {
            return BoardColorTheme(rawValue: UserDefaults.standard.integer(forKey: boardColorThemeKey)) ?? .blackWhite
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: boardColorThemeKey)
        }
    }
    
    private let soundEnabledKey: String = "soundEnabledKey"
    var soundEnabled: Bool {
        get {
            return !UserDefaults.standard.bool(forKey: soundEnabledKey)
        }
        set {
            UserDefaults.standard.setValue(!newValue, forKey: soundEnabledKey)
        }
    }

    private let woodenTableEnabledKey: String = "woodenTableEnabledKey"
    var woodenTableEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: woodenTableEnabledKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: woodenTableEnabledKey)
        }
    }

    private let savedGameFENStringKey: String = "savedGameFENStringKey"
    var savedGameFENString: String? {
        get {
            return UserDefaults.standard.string(forKey: savedGameFENStringKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: savedGameFENStringKey)
        }
    }
}
