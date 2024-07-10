//
//  SettingsView.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List {
            Button {
                viewModel.togglePlayerSide()
            } label: {
                VStack(alignment: .leading) {
                    Text("Player's side")
                        .font(.title3)
                    Text(viewModel.playerSideString)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                viewModel.changeBoardColorTheme()
            } label: {
                VStack(alignment: .leading) {
                    Text("Board's color theme")
                        .font(.title3)
                    Text(viewModel.boardColorTheme.stringRepresentation)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
