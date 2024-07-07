//
//  StartView.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

struct StartView: View {

    @State var isShowingGameScreen: Bool = false
    @State var isShowingSettingsScreen: Bool = false

    let defaults = Defaults()

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    isActive: $isShowingGameScreen,
                    destination: {
                        GameFieldView(
                            viewModel: .init(defaults: defaults),
                            isPresented: $isShowingGameScreen
                        )
                    },
                    label: {
                        Text("Start")
                    }
                )
                NavigationLink(
                    isActive: $isShowingSettingsScreen,
                    destination: {
                        SettingsView(viewModel: .init(defaults: defaults))
                    },
                    label: {
                        Text("Settings")
                    }
                )
            }
            .navigationTitle("Chess")
        }
    }
}
