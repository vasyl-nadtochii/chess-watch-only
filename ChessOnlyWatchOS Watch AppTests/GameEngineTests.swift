//
//  GameEngineTests.swift
//  ChessOnlyWatchOS Watch AppTests
//
//  Created by Vasyl Nadtochii on 20.07.2024.
//

import XCTest
import Accelerate
@testable import ChessOnlyWatchOS_Watch_App

final class GameEngineTests: XCTestCase {

    private var gameEngine: GameEngine!

    private var getAllAvailableMovesCallCount: Int!
    private var getAllAvailableMovesExecutionTimes: [Double]!

    private var pawnMovesProcessed: Int!
    private var knightMovesProcessed: Int!
    private var bishopMovesProcessed: Int!
    private var rookMovesProcessed: Int!
    private var queenMovesProcessed: Int!
    private var kingMovesProcessed: Int!

    override func setUpWithError() throws {
        pawnMovesProcessed = 0
        knightMovesProcessed = 0
        bishopMovesProcessed = 0
        rookMovesProcessed = 0
        queenMovesProcessed = 0
        kingMovesProcessed = 0

        getAllAvailableMovesCallCount = 0
        getAllAvailableMovesExecutionTimes = []

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
        pawnMovesProcessed = 0
        knightMovesProcessed = 0
        bishopMovesProcessed = 0
        rookMovesProcessed = 0
        queenMovesProcessed = 0
        kingMovesProcessed = 0

        getAllAvailableMovesCallCount = 0
        getAllAvailableMovesExecutionTimes = []

        gameEngine = nil
    }

    // MARK: General logic tests

    func testMoveCountForDepth1() {
        XCTAssertEqual(checkMovesCount(depth: 1), 20)
        print(
            "Approximate time spent to get available moves",
            vDSP.mean(getAllAvailableMovesExecutionTimes) * Double(getAllAvailableMovesCallCount)
        )
    }

    func testMoveCountForDepth2() {
        XCTAssertEqual(checkMovesCount(depth: 2), 400)
        print(
            "Approximate time spent to get available moves",
            vDSP.mean(getAllAvailableMovesExecutionTimes) * Double(getAllAvailableMovesCallCount)
        )
    }

    func testMoveCountForDepth3() {
        XCTAssertEqual(checkMovesCount(depth: 3), 8902)
        print(
            "Approximate time spent to get available moves",
            vDSP.mean(getAllAvailableMovesExecutionTimes) * Double(getAllAvailableMovesCallCount)
        )
        print("Pawn moves processed: \(pawnMovesProcessed ?? 0)")
        print("Pawn knight processed: \(knightMovesProcessed ?? 0)")
        print("Pawn bishop processed: \(bishopMovesProcessed ?? 0)")
        print("Pawn rook processed: \(rookMovesProcessed ?? 0)")
        print("Pawn queen processed: \(queenMovesProcessed ?? 0)")
        print("Pawn king processed: \(kingMovesProcessed ?? 0)")
    }

    func testMoveCountForDepth4() {
        XCTAssertEqual(checkMovesCount(depth: 4), 197281)
        print(
            "Approximate time spent to get available moves",
            vDSP.mean(getAllAvailableMovesExecutionTimes) * Double(getAllAvailableMovesCallCount)
        )
        print("Pawn moves processed: \(pawnMovesProcessed ?? 0)")
        print("Pawn knight processed: \(knightMovesProcessed ?? 0)")
        print("Pawn bishop processed: \(bishopMovesProcessed ?? 0)")
        print("Pawn rook processed: \(rookMovesProcessed ?? 0)")
        print("Pawn queen processed: \(queenMovesProcessed ?? 0)")
        print("Pawn king processed: \(kingMovesProcessed ?? 0)")
    }

    // MARK: Performance tests

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

    // MARK: Pawns tests

    func testPawnMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppp1pppp/8/8/8/P2p3P/1PPPPPP1/RNBQKBNR")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailablePawnMoves(
                at: 12,
                for: Piece.pawn | Piece.white,
                shouldIncludeInitialMove: false,
                shouldValidateMoves: false
            )
        }
        let timeSpent = result.0
        let movesCountForPawn = result.1.count

        print("Time spent on pawn moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForPawn, 3)
    }

    // MARK: Knight tests

    func testKnightMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppppp1pp/8/8/2P1P3/P4p1P/1P1P1PP1/RNBQKBNR")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailableKnightMoves(
                at: 6,
                for: Piece.knight | Piece.white,
                shouldIncludeInitialMove: false
            )
        }
        let timeSpent = result.0
        let movesCountForKnight = result.1.count

        print("Time spent on knight moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForKnight, 2)
    }

    // MARK: Bishop tests

    func testBishopMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppppp2p/1P4p1/8/3BP3/P4p1P/2PP1PP1/RNBQK1NR w -")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailableSlidingMoves(
                at: 27,
                for: Piece.bishop | Piece.white,
                onlyAttackMoves: false,
                shouldIncludeInitialMove: false
            )
        }
        let timeSpent = result.0
        let movesCountForBishop = result.1.count

        print("Time spent on bishop moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForBishop, 8)
    }

    // MARK: Rook tests

    func testRookMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppp1pp2/1P4p1/8/3R3p/P6P/2P2PP1/RNBQK1N1 w -")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailableSlidingMoves(
                at: 27,
                for: Piece.rook | Piece.white,
                onlyAttackMoves: false,
                shouldIncludeInitialMove: false
            )
        }
        let timeSpent = result.0
        let movesCountForRook = result.1.count

        print("Time spent on rook moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForRook, 13)
    }

    // MARK: Queen tests

    func testQueenMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppp1pp2/1P4p1/8/3Q3p/P6P/2P2PP1/RNBRK1N1 w -")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailableSlidingMoves(
                at: 27,
                for: Piece.queen | Piece.white,
                onlyAttackMoves: false,
                shouldIncludeInitialMove: false
            )
        }
        let timeSpent = result.0
        let movesCountForQueen = result.1.count

        print("Time spent on queen moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForQueen, 21)
    }

    // MARK: King tests

    func testKingMovesCount() {
        gameEngine = .init(defaults: MockDefaults(), fenString: "rnbqkbnr/ppp1p3/1P4p1/8/2R4p/P4p1P/2P3P1/RNB1KN2 w -")
        gameEngine.gameMode = .playerVsPlayer
        let result = measureElapsedTimeAndReturnValue {
            gameEngine.getAvailableKingMoves(
                at: 4,
                for: Piece.king | Piece.white,
                onlyAttackMoves: false,
                shouldIncludeInitialMove: false
            )
        }
        let timeSpent = result.0
        let movesCountForKing = result.1.count

        print("Time spent on king moves calculation: \(timeSpent)")
        XCTAssertEqual(movesCountForKing, 1)
    }

    private func checkMovesCount(depth: Int) -> Int? {
        guard depth >= 0 else { return nil }
        if depth == 0 {
            return 1
        }
        
        let movesAndTimeForExecution = measureElapsedTimeAndReturnValue {
            gameEngine.getAllAvailableMoves(
                forSide: nil,
                shouldIncludeInitialMove: false,
                shouldValidateMoves: false
            )
        }

        getAllAvailableMovesExecutionTimes.append(movesAndTimeForExecution.0)
        getAllAvailableMovesCallCount += 1

        let moves = movesAndTimeForExecution.1
        var positionsNumber = 0
        
        for move in moves {
            guard let pieceAtMoveStartIndex = gameEngine.board[move.startSquare] else {
                XCTFail("Couldn't get piece at move start index for \(move.startSquare)")
                return nil
            }

            let pieceTypeAtMoveStartIndex = Piece.pieceType(from: gameEngine.board[move.startSquare] ?? 0)

            switch pieceTypeAtMoveStartIndex {
            case Piece.pawn:
                pawnMovesProcessed += 1
            case Piece.knight:
                knightMovesProcessed += 1
            case Piece.bishop:
                bishopMovesProcessed += 1
            case Piece.rook:
                rookMovesProcessed += 1
            case Piece.queen:
                queenMovesProcessed += 1
            case Piece.king:
                kingMovesProcessed += 1
            default:
                break
            }

            if gameEngine.makeMove(move: move, piece: pieceAtMoveStartIndex, shouldValidateMove: true) {
                positionsNumber += checkMovesCount(depth: depth - 1) ?? 0
                gameEngine.unmakeMove()
            }
        }
        
        return positionsNumber
    }
}
