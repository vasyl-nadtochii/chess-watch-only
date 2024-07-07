//
//  GameFieldViewModel.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation
import SwiftUI

class GameFieldViewModel: ObservableObject {

    enum SelectButtonAction {
        case select
        case makeMove
    }

    enum CancelButtonAction {
        case exit
        case cancelSelection
    }

    var board: Board

    var selectButtonColor: Color {
        switch selectButtonAction {
        case .select:
            return .blue
        case .makeMove:
            return .green
        }
    }

    var selectButtonTitle: String {
        switch selectButtonAction {
        case .select:
            return "Select"
        case .makeMove:
            return "Move"
        }
    }

    var cancelButtonTitle: String {
        switch cancelButtonAction {
        case .exit:
            "Exit"
        case .cancelSelection:
            "Cancel"
        }
    }

    @Published var selectButtonAction: SelectButtonAction = .select
    var cancelButtonAction: CancelButtonAction {
        switch selectButtonAction {
        case .select:
            return .exit
        case .makeMove:
            return .cancelSelection
        }
    }

    @Published var selectedCellIndex: Int = 0

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.board = .init(defaults: defaults)
        self.setInitialCursorPosition()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.setInitialCursorPosition()
        }
    }

    var availableCellsIndiciesForPlayerToPick: [Int] {
        let allCells = Array(0...(board.squares.count - 1))
        return allCells.filter({
            guard let piece = getPieceAtCell(index: $0) else {
                return false
            }
            return Piece.pieceColor(from: piece) == board.playerSide
        })
    }

    func getPieceAtCell(index: Int) -> Int? {
        let valueAtCell = board.squares[safe: index]
        if valueAtCell == 0 {
            return nil
        }
        return valueAtCell
    }

    func getCellIndex(file: Int, rank: Int) -> Int {
        return (8 - file) * 8 + rank - 1
    }

    func isCellSelected(file: Int, rank: Int) -> Bool {
        return getCellIndex(file: file, rank: rank) == selectedCellIndex
    }

    func onSelectButtonTapped() {
        if selectButtonAction == .select {
            selectButtonAction = .makeMove
        }
    }

    func onCancelButtonTapped(dismissClosure: () -> Void) {
        if selectButtonAction == .select {
            dismissClosure()
        } else {
            selectButtonAction = .select
        }
    }

    private func setInitialCursorPosition() {
        selectedCellIndex = availableCellsIndiciesForPlayerToPick.min() ?? 0
    }
}
