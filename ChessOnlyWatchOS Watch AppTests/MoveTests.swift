//
//  MoveTests.swift
//  ChessOnlyWatchOS Watch AppTests
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation
import XCTest

@testable import ChessOnlyWatchOS_Watch_App

final class MoveTests: XCTestCase {

    func testSANConverting() {
        var move = Move(startSquare: 10, targetSquare: 26)
        XCTAssertEqual(move.moveToSANString(), "c2c4")
    }
}
