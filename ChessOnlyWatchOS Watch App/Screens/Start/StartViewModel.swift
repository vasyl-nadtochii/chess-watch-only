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

    var gameFieldViewModel: GameFieldViewModel
    let defaults = Defaults()

    init() {
        gameFieldViewModel = .init(
            defaults: defaults,
            gameEngine: .init(defaults: defaults, aiEngine: AIEngineImpl())
        )
    }
}
