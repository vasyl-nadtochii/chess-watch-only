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

    var cancelButtonAction: CancelButtonAction {
        switch selectButtonAction {
        case .select:
            return .exit
        case .makeMove:
            return .cancelSelection
        }
    }

    var shouldHighlightAvailableCells: Bool {
        return selectButtonAction == .makeMove
    }

    var availableCellsIndiciesForPlayerToPick: [Int] {
        let allCells = Array(0...(board.squares.count - 1))
        switch selectButtonAction {
        case .select:
            return allCells.filter({
                guard let piece = getPieceAtCell(index: $0) else {
                    return false
                }
                return Piece.pieceColor(from: piece) == board.playerSide
            })
        case .makeMove:
            guard let selectedCellIndex = selectedCellIndex,
                let pieceAtCell = getPieceAtCell(index: selectedCellIndex),
                let selectedPieceType = Piece.pieceType(from: pieceAtCell)
            else { return [] }

            switch selectedPieceType {
            case Piece.king:
                return []
            case Piece.pawn:
                return board.getAvailablePawnMoves(at: selectedCellIndex, for: pieceAtCell)
                    .map { $0.targetSquare }
            case Piece.bishop, Piece.queen, Piece.rook:
                return board.getAvailableSlidingMoves(at: selectedCellIndex, for: pieceAtCell)
                    .map { $0.targetSquare }
            default:
                return []
            }
        }
    }

    @Published var selectButtonAction: SelectButtonAction = .select
    @Published var cursorCellIndex: Int = 0 // cell at which points cursor
    @Published var selectedCellIndex: Int? // cell which was selected by pressing "Select"

    private let defaults: Defaults

    init(defaults: Defaults) {
        self.defaults = defaults
        self.board = .init(defaults: defaults)
        self.setInitialCursorPosition()

        NotificationCenter.default.addObserver(forName: .playerSideUpdated, object: nil, queue: .main) { _ in
            self.setInitialCursorPosition()
        }
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

    func isCursorPointingAtCell(file: Int, rank: Int) -> Bool {
        return getCellIndex(file: file, rank: rank) == cursorCellIndex
    }

    func onSelectButtonTapped() {
        if selectButtonAction == .select {
            selectedCellIndex = cursorCellIndex
            selectButtonAction = .makeMove
        } else {
            guard let selectedCellIndex = selectedCellIndex,
                let piece = getPieceAtCell(index: selectedCellIndex)
            else {
                return
            }
            guard board.makeMove(
                move: .init(startSquare: selectedCellIndex, targetSquare: cursorCellIndex),
                piece: piece
            ) else {
                return
            }
            self.selectedCellIndex = nil
            selectButtonAction = .select
        }
    }

    func onCancelButtonTapped(dismissClosure: () -> Void) {
        if selectButtonAction == .select {
            dismissClosure()
        } else {
            if let selectedCellIndex = selectedCellIndex {
                cursorCellIndex = selectedCellIndex
                self.selectedCellIndex = nil
            }
            selectButtonAction = .select
        }
    }

    private func setInitialCursorPosition() {
        cursorCellIndex = availableCellsIndiciesForPlayerToPick.min() ?? 0
    }
}
