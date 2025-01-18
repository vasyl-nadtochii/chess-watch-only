//
//  StartViewModel.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 18.01.2025.
//

import Foundation

class StartViewModel: ObservableObject {

    @Published var isShowingGameScreen: Bool = false
    @Published var isShowingSettingsScreen: Bool = false
    @Published var continueFromSaveAvailable: Bool = false
    @Published var isShowingAlert: Bool = false

    var gameFieldViewModel: GameFieldViewModel
    let defaults = Defaults()

    let newGameWarning = "Are you sure you want to start new game?\nYour saved game will be deleted!"

    init() {
        gameFieldViewModel = .init(
            defaults: defaults,
            gameEngine: .init(defaults: defaults, aiEngine: AIEngineImpl())
        )
    }

    func startNewGameIfCan() {
        guard defaults.savedGameFENString == nil else {
            isShowingAlert = true
            return
        }
        startNewGame()
    }

    func startNewGame() {
        gameFieldViewModel = .init(
            defaults: defaults,
            gameEngine: .init(defaults: defaults, aiEngine: AIEngineImpl())
        )
        isShowingGameScreen = true

        defaults.savedGameFENString = nil
        continueFromSaveAvailable = false
    }

    func continueFromSave() {
        guard let fenString = defaults.savedGameFENString else {
            print("Attempted to continue game without save string")
            return
        }

        gameFieldViewModel = .init(
            defaults: defaults,
            gameEngine: .init(defaults: defaults, aiEngine: AIEngineImpl(), fenString: fenString)
        )
        isShowingGameScreen = true
    }

    func onViewWillAppear() {
        continueFromSaveAvailable = (
            defaults.savedGameFENString != nil && defaults.savedGameFENString?.isEmpty == false
        )
    }
}
