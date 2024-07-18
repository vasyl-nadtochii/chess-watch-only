//
//  GameFieldViewModel.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation
import SwiftUI
import WatchKit
import AVFoundation

class GameFieldViewModel: ObservableObject {

    enum SelectButtonAction {
        case select
        case makeMove
    }

    enum CancelButtonAction {
        case exit
        case cancelSelection
    }
    
    enum SoundType {
        case move
        case capture
        case check
        case castle
    }

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

    var pawnPromotionOptions: [Int] {
        return Piece.pawnPromotionOptions
    }

    var shouldHighlightAvailableCells: Bool {
        return selectButtonAction == .makeMove
    }

    var availableCellsIndiciesToPick: [Int] = []
    var gameEngine: GameEngine
    var currentColorTheme: BoardColorTheme

    var pawnToPromote: Int?
    var pawnIndexToPromote: Int?

    @Published var selectButtonAction: SelectButtonAction = .select
    @Published var cursorCellIndex: Int = 0 // cell at which points cursor
    @Published var selectedCellIndex: Int? // cell which was selected by pressing "Select"
    @Published var isShowingPawnPromotionOptions: Bool = false
    @Published var boardPosition: BoardPosition
    @Published var sideToMove: Int

    private let defaults: Defaults
    private let avPlayer: AVPlayer

    init(defaults: Defaults) {
        self.defaults = defaults
        self.avPlayer = AVPlayer()
        self.avPlayer.automaticallyWaitsToMinimizeStalling = false

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setMode(.moviePlayback)
            AVAudioSession.sharedInstance().activate(completionHandler: { success, error in
                if let error = error {
                    print("Error while activating AudioSession: \(error.localizedDescription)")
                } else {
                    print("AVAudioSession activated - \(success)")
                }
            })
        } catch {
            print("Error occurred: \(error.localizedDescription)")
        }

        if let defaultPath = Bundle.main.path(forResource: "move-self", ofType: "mp3") {
            self.avPlayer.replaceCurrentItem(with: .init(url: URL(fileURLWithPath: defaultPath)))
        }

        self.gameEngine = .init(defaults: defaults)
        self.boardPosition = gameEngine.boardPosition
        self.sideToMove = gameEngine.sideToMove
        self.currentColorTheme = defaults.boardColorTheme
        self.gameEngine.onResult = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .pawnShouldBePromoted(let pawn, let pawnIndex):
                self.pawnToPromote = pawn
                self.pawnIndexToPromote = pawnIndex
                self.isShowingPawnPromotionOptions = true
            case .playerSideUpdated:
                self.boardPosition = self.gameEngine.boardPosition
                self.setInitialCursorPosition()
            case .sideToMoveChanged:
                self.sideToMove = self.gameEngine.sideToMove
            case .madePlainMove:
                self.playSoundIfNeed(type: .move)
            case .capturedPiece:
                self.playSoundIfNeed(type: .capture)
            case .madeCastleMove:
                self.playSoundIfNeed(type: .castle)
            }
        }

        self.updateAvailableCellsToPickMove()
        self.setInitialCursorPosition()

        NotificationCenter.default.addObserver(forName: .boardColorThemeUpdated, object: nil, queue: .main) { _ in
            self.currentColorTheme = defaults.boardColorTheme
        }
    }

    func getPieceAtCell(index: Int) -> Int? {
        let valueAtCell = gameEngine.squares[safe: index]
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
            updateAvailableCellsToPickMove()
        } else {
            guard let selectedCellIndex = selectedCellIndex,
                let piece = getPieceAtCell(index: selectedCellIndex)
            else {
                return
            }
            guard gameEngine.makeMove(
                move: .init(startSquare: selectedCellIndex, targetSquare: cursorCellIndex),
                piece: piece
            ) else {
                return
            }
            self.selectedCellIndex = nil
            self.selectButtonAction = .select
            updateAvailableCellsToPickMove()
            setInitialCursorPosition()
            WKInterfaceDevice.current().play(.click)
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
        updateAvailableCellsToPickMove()
    }

    func promotePawn(at squareIndex: Int, from pawn: Int, to newPieceType: Int) {
        gameEngine.promotePawn(at: squareIndex, from: pawn, to: newPieceType)
        pawnIndexToPromote = nil
        pawnToPromote = nil
    }

    private func setInitialCursorPosition() {
        cursorCellIndex = availableCellsIndiciesToPick.min() ?? 0
    }
    
    private func playSoundIfNeed(type: SoundType) {
        guard defaults.soundEnabled else { return }

        let pathName: String
        switch type {
        case .move:
            pathName = "move-self"
        case .capture:
            pathName = "capture"
        case .check:
            pathName = "move-check"
        case .castle:
            pathName = "castle"
        }
        
        guard let path = Bundle.main.path(forResource: pathName, ofType: "mp3") else {
            return
        }

        avPlayer.replaceCurrentItem(with: .init(url: URL(fileURLWithPath: path)))
        avPlayer.play()
    }

    private func updateAvailableCellsToPickMove() {
        let allCells = Array(0...(gameEngine.squares.count - 1))
        switch selectButtonAction {
        case .select:
            self.availableCellsIndiciesToPick = allCells.filter({
                guard let piece = getPieceAtCell(index: $0) else {
                    return false
                }
                return Piece.pieceColor(from: piece) == sideToMove
            })
        case .makeMove:
            guard let selectedCellIndex = selectedCellIndex else {
                self.availableCellsIndiciesToPick = []
                return
            }
            self.availableCellsIndiciesToPick = gameEngine.getAvailableMoves(at: selectedCellIndex, for: getPieceAtCell(index: selectedCellIndex))
                .map { $0.targetSquare }
                .sorted(by: { $0 > $1 })
        }
    }
}
