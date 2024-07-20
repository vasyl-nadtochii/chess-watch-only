//
//  MockDefaults.swift
//  ChessOnlyWatchOS Watch AppTests
//
//  Created by Vasyl Nadtochii on 20.07.2024.
//

import Foundation
@testable import ChessOnlyWatchOS_Watch_App

class MockDefaults: IDefaults {

    var playerSide: Int = Piece.white
    var boardColorTheme: BoardColorTheme = .blackWhite
    var soundEnabled: Bool = false
}
