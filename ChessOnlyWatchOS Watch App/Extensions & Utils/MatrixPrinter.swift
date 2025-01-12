//
//  MatrixPrinter.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation
import CoreML

class MatrixPrinter {

    static func prettyPrintMatrix<T>(_ matrix: [[T]]) {
        for row in matrix {
            let rowString = row.map { "\($0)" }.joined(separator: "\t")
            print(rowString)
        }
    }

    static func prettyPrintMultiArray(_ multiArray: MLMultiArray) {
        // Ensure the array has at least one dimension
        guard multiArray.shape.count > 0 else {
            print("MLMultiArray is empty.")
            return
        }

        // Get the shape of the array
        let shape = multiArray.shape.map { $0.intValue }

        // Helper function to calculate the flattened index
        func calculateFlatIndex(indices: [Int], strides: [Int]) -> Int {
            return zip(indices, strides).reduce(0) { $0 + $1.0 * $1.1 }
        }

        // Helper function to recursively access and print values
        func printMultiArray(_ array: MLMultiArray, indices: [Int] = [], depth: Int = 0) {
            if indices.count == shape.count - 1 {
                // Last dimension: print the values
                let values = (0..<shape[indices.count]).map { i -> String in
                    var currentIndices = indices
                    currentIndices.append(i)
                    let flatIndex = calculateFlatIndex(indices: currentIndices, strides: array.strides.map { $0.intValue })
                    return String(format: "%.2f", array[flatIndex].floatValue)
                }
                print(String(repeating: "\t", count: depth) + "[\(values.joined(separator: ", "))]")
            } else {
                // Other dimensions: recursively go deeper
                print(String(repeating: "\t", count: depth) + "[")
                for i in 0..<shape[indices.count] {
                    var currentIndices = indices
                    currentIndices.append(i)
                    printMultiArray(array, indices: currentIndices, depth: depth + 1)
                }
                print(String(repeating: "\t", count: depth) + "]")
            }
        }

        // Start printing the array
        printMultiArray(multiArray)
    }
}
