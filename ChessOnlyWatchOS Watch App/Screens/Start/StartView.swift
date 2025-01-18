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
            .alert(
                viewModel.newGameWarning,
                isPresented: $viewModel.isShowingAlert,
                actions: {
                    Button("Yes, start new game") {
                        viewModel.isShowingAlert = false
                        viewModel.startNewGame()
                    }
                    Button("No, go back") {
                        viewModel.isShowingAlert = false
                    }
                }
            )
        }
    }

    var buttons: some View {
        ScrollView {
            VStack(spacing: 10) {
                if viewModel.continueFromSaveAvailable {
                    Button("Continue") {
                        viewModel.continueFromSave()
                    }
                }
                Button("New Game") {
                    viewModel.startNewGameIfCan()
                }
                Button("Settings") {
                    viewModel.isShowingSettingsScreen = true
                }
            }
            .padding(.vertical, 12)
            .onAppear {
                viewModel.onViewWillAppear()
            }
        }
    }
}
