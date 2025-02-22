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
        TabView(selection: $viewModel.currentTab) {
            ZStack {
                VStack(spacing: 0) {
                    gameField
                    Spacer()
                    buttons
                }
                .applySafeAreaOffsetIfNeed()
                cellPicker
            }
            .tag(GameFieldViewModel.Tab.board)

            Text("Side menu")
                .tag(GameFieldViewModel.Tab.sideMenu)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(
            Color.getBoardBackgroundColor(theme: viewModel.currentColorTheme)
                .overlay {
                    if viewModel.woodenTableEnabled {
                        Image.woodTexture
                            .resizable()
                            .scaledToFill()
                    }
                }
                .ignoresSafeArea()
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.makeComputerMoveIfNeed()
            }
        }
        .alert(
            "Promote your pawn to:",
            isPresented: $viewModel.isShowingPawnPromotionOptions,
            actions: {
                ForEach(viewModel.pawnPromotionOptions, id: \.self) { promotionOption in
                    Button(Piece.pieceName(fromType: promotionOption)) {
                        guard let pawnToPromote = viewModel.pawnToPromote,
                            let pawnIndexToPromote = viewModel.pawnIndexToPromote
                        else {
                            return
                        }
                        viewModel.promotePawn(at: pawnIndexToPromote, from: pawnToPromote, to: promotionOption)
                    }
                }
            }
        )
        .navigationBarBackButtonHidden()
        .edgesIgnoringSafeArea(.bottom)
        .hideNavigationBarIfNeed()
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
                                            .border(viewModel.cursorColor, width: 2)
                                            .opacity(viewModel.pickerDisabled ? 0 : 1)
                                    }
                                    if viewModel.shouldHighlightAvailableCells
                                        && viewModel.availableCellsIndiciesToPick.contains(where: {
                                            $0 == viewModel.getCellIndex(file: file, rank: rank)
                                        }) {
                                        Color.green.opacity(0.15)
                                            .frame(width: gameFieldHeight / 8, height: gameFieldHeight / 8)
                                    }
                                    drawPieceIfNeed(file: file, rank: rank)
                                }
                            }
                            .rotationEffect(.degrees(viewModel.boardPosition == .blackBelowWhiteAbove ? 180 : 0))
                    }
                }
            }
        }
        .rotationEffect(.degrees(viewModel.boardPosition == .blackBelowWhiteAbove ? 180 : 0))
        .frame(width: gameFieldHeight, height: gameFieldHeight)
    }

    var buttons: some View {
        HStack {
            CompactButton(text: viewModel.cancelButtonTitle, color: .cancelButtonColor) {
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
            availableCellIndicies: viewModel.availableCellsIndiciesToPick,
            currentIndex: $viewModel.cursorCellIndex
        )
        .disabled(viewModel.pickerDisabled)
    }

    private var gameFieldHeight: CGFloat {
        return WKInterfaceDevice.current().screenBounds.width * 0.82
    }

    private func createCell(file: Int, rank: Int) -> some View {
        Rectangle()
            .fill(
                ((file + rank) - 1) % 2 == 0
                    ? Color.getCellBlackColor(theme: viewModel.currentColorTheme)
                    : Color.getCellWhiteColor(theme: viewModel.currentColorTheme)
            )
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
