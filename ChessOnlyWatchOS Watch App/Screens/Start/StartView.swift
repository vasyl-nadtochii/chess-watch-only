//
//  StartView.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

struct StartView: View {

    @ObservedObject var viewModel: StartViewModel

    var body: some View {
        NavigationView {
            ZStack {
                buttons
                NavigationLink(
                    isActive: $viewModel.isShowingGameScreen,
                    destination: {
                        GameFieldView(
                            viewModel: viewModel.gameFieldViewModel,
                            isPresented: $viewModel.isShowingGameScreen
                        )
                    },
                    label: {}
                )
                .buttonStyle(PlainButtonStyle())
                NavigationLink(
                    isActive: $viewModel.isShowingSettingsScreen,
                    destination: {
                        SettingsView(viewModel: .init(defaults: viewModel.defaults))
                    },
                    label: {}
                )
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Chess")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var buttons: some View {
        VStack {
            Button("Start") {
                viewModel.isShowingGameScreen = true
            }
            Button("Settings") {
                viewModel.isShowingSettingsScreen = true
            }
        }
    }
}
