//
//  GameFieldView.swift
//  ChessOnlyWatchOS Watch App
//
//  Created by Vasyl Nadtochii on 07.07.2024.
//

import SwiftUI
import WatchKit

struct GameFieldView: View {

    @ObservedObject var viewModel: GameFieldViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                gameField
                Spacer()
                buttons
            }
            cellPicker
        }
        .background(Color("FieldBackgroundColor"))
        .navigationBarBackButtonHidden()
        .edgesIgnoringSafeArea(.bottom)
    }

    var gameField: some View {
        VStack(spacing: 0) {
            ForEach(1...8, id: \.self) { file in
                HStack(spacing: 0) {
                    ForEach(1...8, id: \.self) { rank in
                        createCell(file: file, rank: rank)
                            .overlay {
                                ZStack {
                                    if viewModel.isCursorPointingAtCell(file: file, rank: rank) {
                                        Color.clear
                                            .frame(width: gameFieldHeight / 8, height: gameFieldHeight / 8)
                                            .border(viewModel.selectButtonColor, width: 2)
                                    }
                                    if viewModel.shouldHighlightAvailableCells
                                        && viewModel.availableCellsIndiciesForPlayerToPick.contains(where: {
                                            $0 == viewModel.getCellIndex(file: file, rank: rank)
                                        }) {
                                        Color.green.opacity(0.15)
                                            .frame(width: gameFieldHeight / 8, height: gameFieldHeight / 8)
                                    }
                                    drawPieceIfNeed(file: file, rank: rank)
                                }
                            }
                    }
                }
            }
        }
        .frame(width: gameFieldHeight, height: gameFieldHeight)
    }

    var buttons: some View {
        HStack {
            CompactButton(text: viewModel.cancelButtonTitle, color: .red) {
                viewModel.onCancelButtonTapped {
                    isPresented = false
                }
            }
            CompactButton(
                text: viewModel.selectButtonTitle,
                color: viewModel.selectButtonColor,
                action: viewModel.onSelectButtonTapped
            )
        }
        .padding(.horizontal)
    }

    var cellPicker: some View {
        CellPicker(
            availableCellIndicies: viewModel.availableCellsIndiciesForPlayerToPick,
            currentIndex: $viewModel.cursorCellIndex
        )
    }

    private var gameFieldHeight: CGFloat {
        return WKInterfaceDevice.current().screenBounds.width * 0.82
    }

    private func createCell(file: Int, rank: Int) -> some View {
        Rectangle()
            .fill(((file + rank) - 1) % 2 == 0 ? Color("FieldBlackColor") : Color("FieldWhiteColor"))
            .frame(width: gameFieldHeight / 8, height: gameFieldHeight / 8)
    }

    private func drawPieceIfNeed(file: Int, rank: Int) -> some View {
        let cellNumber = viewModel.getCellIndex(file: file, rank: rank)

        if let pieceAtCell = viewModel.getPieceAtCell(index: cellNumber),
           let pieceName = Piece.iconNameFromInt(pieceAtCell) {
            return Image(pieceName)
                .resizable()
                .frame(width: gameFieldHeight / 8, height: gameFieldHeight / 8)
                .anyView
        } else {
            return EmptyView().anyView
        }
    }
}
