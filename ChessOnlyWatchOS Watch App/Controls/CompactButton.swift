//
//  CompactButton.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

struct CompactButton: View {

    var text: String
    var color: Color = .gray
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 26)
                .shadow(radius: 4)
                .overlay {
                    Text(text)
                }
        }
        .buttonStyle(.plain)
    }
}
