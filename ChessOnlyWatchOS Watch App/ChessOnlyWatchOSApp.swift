//
//  ChessOnlyWatchOSApp.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

@main
struct ChessOnlyWatchOS_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            StartView(viewModel: .init())
        }
    }
}
