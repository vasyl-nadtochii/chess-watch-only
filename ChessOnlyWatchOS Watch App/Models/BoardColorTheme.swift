//
//  BoardColorTheme.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 10.07.2024.
//

import Foundation

enum BoardColorTheme: Int, CaseIterable {

    case blackWhite = 0
    case brown = 1
    case blue = 2
    case green = 3
    case red = 4
}

extension BoardColorTheme {

    var stringRepresentation: String {
        switch self {
        case .blackWhite:
            return "BlackWhite"
        case .brown:
            return "Brown"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .red:
            return "Red"
        }
    }
}
