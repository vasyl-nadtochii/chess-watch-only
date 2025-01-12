//
//  Move.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation

extension Move {

    func toSANMoveString() -> String {
        let columns = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let rows = Array(1...8)

        let startCellColumnIndex = self.startSquare % 8
        let targetCellColumnIndex = self.targetSquare % 8

        let startCellRowIndex = self.startSquare / 8
        let targetCellRowIndex = self.targetSquare / 8

        return "\(columns[startCellColumnIndex])\(rows[startCellRowIndex])\(columns[targetCellColumnIndex])\(rows[targetCellRowIndex])"
    }
}

extension String {

    func fromSANString() -> Move? {
        let columns = ["a", "b", "c", "d", "e", "f", "g", "h"]

        let fromCell = self.prefix(2)
        let toCell = self.suffix(2)

        let fromColumn = columns.firstIndex(of: String(fromCell.prefix(1)))
        let toColumn = columns.firstIndex(of: String(toCell.prefix(1)))

        let fromRow = Int(fromCell.suffix(1))
        let toRow = Int(toCell.suffix(1))

        guard let fromRow, let fromColumn, let toRow, let toColumn else {
            print("Invalid SAN move: \(self)")
            return nil
        }

        return Move(
            startSquare: (fromRow - 1) * 8 + fromColumn,
            targetSquare: (toRow - 1) * 8 + toColumn
        )
    }
}
