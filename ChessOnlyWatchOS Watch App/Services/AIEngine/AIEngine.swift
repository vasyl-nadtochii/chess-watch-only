//
//  AIEngine.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation
import CoreML

protocol AIEngine {}

class AIEngineImpl: AIEngine {

    let model: chess_model_from_export?

    init() {
        let config = MLModelConfiguration()
        do {
            self.model = try .init(configuration: config)
        } catch {
            self.model = nil
            print("AI MODEL INIT ERROR: \(error.localizedDescription)")
        }
    }

    func predictMoves(legalMoves: [String]) {
        let matrix = Array(
            repeating: Array(
                repeating: Array(
                    repeating: 0.0,
                    count: 8
                ),
                count: 8
            ),
            count: 13
        )
    }
}
