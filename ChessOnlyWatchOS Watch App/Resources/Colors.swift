//
//  Colors.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 10.07.2024.
//

import SwiftUI

extension Color {

    static func getCellBlackColor(theme: BoardColorTheme) -> Color {
        return Color("FieldBlackColor\(theme.stringRepresentation)")
    }

    static func getCellWhiteColor(theme: BoardColorTheme) -> Color {
        return Color("FieldWhiteColor\(theme.stringRepresentation)")
    }

    static func getBoardBackgroundColor(theme: BoardColorTheme) -> Color {
        return Color("FieldBackgroundColor\(theme.stringRepresentation)")
    }
}
