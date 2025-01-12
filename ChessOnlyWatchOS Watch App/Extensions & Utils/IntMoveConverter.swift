//
//  IntMoveConverter.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 12.01.2025.
//

import Foundation

class IntMoveConverter {

    static let moveToInt: [String: Int]? = {
        if let path = Bundle.main.path(forResource: "heavy_move_to_int", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, Int> {
                    return jsonResult
                }
                return nil
            } catch {
                print("Error while reading heavy_move_to_int.json: \(error.localizedDescription)")
                return nil
            }
        } else {
            print("Unable to find heavy_move_to_int.json file at given path")
            return nil
        }
    }()

    static let intToMove: [Int: String]? = {
        guard let moveToInt else {
            return nil
        }

        var result: [Int: String] = [:]
        for pair in moveToInt { result[pair.value] = pair.key }

        return result
    }()
}
