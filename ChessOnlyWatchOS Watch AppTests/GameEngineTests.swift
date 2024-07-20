//
//  GameEngineTests.swift
//  ChessOnlyWatchOS Watch AppTests
//
//  Created by Vasyl Nadtochii on 20.07.2024.
//

import XCTest
@testable import ChessOnlyWatchOS_Watch_App

final class GameEngineTests: XCTestCase {

    private var gameEngine: GameEngine!

    override func setUpWithError() throws {
        gameEngine = .init(defaults: MockDefaults())
        gameEngine.gameMode = .playerVsPlayer
    }

    override func tearDownWithError() throws {
        gameEngine = nil
    }

    func testMovesCount() {
        XCTAssertEqual(checkMovesCount(depth: 1), 20)
        XCTAssertEqual(checkMovesCount(depth: 2), 400)
        XCTAssertEqual(checkMovesCount(depth: 3), 8902)
    }

    func testMoveCountForLargerDepth() {
        XCTAssertEqual(checkMovesCount(depth: 4), 197281)
    }

    func testCalculationTime() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            XCTAssertEqual(checkMovesCount(depth: 3), 8902)
            stopMeasuring()
        }
    }

    private func checkMovesCount(depth: Int) -> Int? {
        guard depth >= 0 else { return nil }
        if depth == 0 {
            return 1
        }

        let moves = gameEngine.getAllAvailableMoves(forSide: nil).filter({ $0.startSquare != $0.targetSquare })
        var positionsNumber = 0

        for move in moves {
            guard let pieceAtMoveStartIndex = gameEngine.squares[safe: move.startSquare] else {
                XCTFail("Couldn't get piece at move start index for \(move.startSquare)")
                return nil
            }
            if gameEngine.makeMove(move: move, piece: pieceAtMoveStartIndex) {
                positionsNumber += checkMovesCount(depth: depth - 1) ?? 0
                gameEngine.unmakeMove()
            }
        }

        return positionsNumber
    }
}
