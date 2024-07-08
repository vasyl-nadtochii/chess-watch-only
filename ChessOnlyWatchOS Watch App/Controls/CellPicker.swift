//
//  CellPicker.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import Foundation
import SwiftUI
import Combine

struct CellPicker: View {

    var availableCellIndicies: [Int]
    @Binding var currentIndex: Int

    var body: some View {
        Picker(selection: $currentIndex) {
            ForEach(availableCellIndicies, id: \.self) { _ in
                Text(String())
                    .frame(height: 100)
            }
        } label: {
            Text(String())
                .frame(height: 100)
        }
        .opacity(0)
    }
}
