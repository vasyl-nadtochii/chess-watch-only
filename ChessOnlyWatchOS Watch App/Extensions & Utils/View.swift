//
//  View.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI

extension View {

    var anyView: AnyView {
        return AnyView(self)
    }
    
    func hideNavigationBarIfNeed() -> some View {
        if #available(watchOS 10.0, *) {
            return self
        } else {
            return self.navigationBarHidden(true)
        }
    }
    
    func applySafeAreaOffsetIfNeed() -> some View {
        if #available(watchOS 10.0, *) {
            return self
        } else {
            return self.padding(.top, 10)
        }
    }
}
