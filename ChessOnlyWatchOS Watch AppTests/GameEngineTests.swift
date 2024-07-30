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
        gameEngine = .init(defaults: MockDefaults(), fenString: Constants.initialChessPosition)
        gameEngine.gameMode = .playerVsPlayer
        gameEngine.onResult = { result in
            switch result {
            case .pawnShouldBePromoted(pawn: let pawn, pawnIndex: let pawnIndex):
                if let color = Piece.pieceColor(from: pawn) {
                    self.gameEngine.promotePawn(at: pawnIndex, from: pawn, to: Piece.queen | color)
                }
            default:
                break
            }
        }
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

    func testCalculationTimeForDepth1() {
        measure {
            XCTAssertEqual(checkMovesCount(depth: 1), 20)
        }
    }

    func testCalculationTimeForDepth2() {
        measure {
            XCTAssertEqual(checkMovesCount(depth: 2), 400)
        }
    }

    func testCalculationTimeForDepth3() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            XCTAssertEqual(checkMovesCount(depth: 3), 8902)
            stopMeasuring()
        }
    }

    func testCalculationTimeForDepth4() {
        measure {
            XCTAssertEqual(checkMovesCount(depth: 4), 197281)
        }
    }

    private func checkMovesCount(depth: Int) -> Int? {
        guard depth >= 0 else { return nil }
        if depth == 0 {
            return 1
        }

        let moves = gameEngine.getAllAvailableMoves(
            forSide: nil,
            shouldIncludeInitialMove: false,
            shouldValidateMoves: false
        )
        var positionsNumber = 0

        for move in moves {
            guard let pieceAtMoveStartIndex = gameEngine.board[move.startSquare] else {
                XCTFail("Couldn't get piece at move start index for \(move.startSquare)")
                return nil
            }
            if gameEngine.makeMove(move: move, piece: pieceAtMoveStartIndex, shouldValidateMove: true) {
                positionsNumber += checkMovesCount(depth: depth - 1) ?? 0
                gameEngine.unmakeMove()
            }
        }

        return positionsNumber
    }
}
