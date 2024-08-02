//
//  MeasureTime.swift
//  ChessOnlyWatchOS Watch AppTests
//
//  Created by Vasyl Nadtochii on 02.08.2024.
//

import Foundation

func measureElapsedTimeAndReturnValue<T>(_ operation: () -> T) -> (Double, T) {
    let startTime = DispatchTime.now()
    let valueToReturn = operation()
    let endTime = DispatchTime.now()

    let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds

    return (Double(elapsedTime) / 1_000_000_000, valueToReturn)
}
