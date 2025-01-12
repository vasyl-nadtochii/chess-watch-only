//
//  Move.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation

extension Move {

    func moveToSANString() -> String {
        let columns = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let rows = Array(1...8)

        let startCellColumnIndex = self.startSquare % 8
        let targetCellColumnIndex = self.targetSquare % 8

        let startCellRowIndex = self.startSquare / 8
        let targetCellRowIndex = self.targetSquare / 8

        return "\(columns[startCellColumnIndex])\(rows[startCellRowIndex])\(columns[targetCellColumnIndex])\(rows[targetCellRowIndex])"
    }
}
