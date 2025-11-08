//
//  AIStrategy.swift
//  TicTacToe
//
//  Created by Keith Elliott on 6/28/16.
//  Copyright © 2016 GittieLabs. All rights reserved.
//

import GameplayKit
import Foundation

enum PlayerType: Int{
    case x
    case o
    case none
}

enum GameState: Int{
    case winner
    case draw
    case playing
}

struct BoardCell{
    var value: PlayerType
    var node: String
}

@objc(Player)
class Player: NSObject, GKGameModelPlayer{
    let _player: Int
    
    init(player:Int) {
        _player = player
        super.init()
    }
    
    var playerId: Int{
        return _player
    }
}

@objc(Move)
class Move: NSObject, GKGameModelUpdate{
    var value: Int = 0
    var cell: Int
    
    init(cell: Int){
        self.cell = cell
        super.init()
    }
}

@objc(Board)
class Board: NSObject, NSCopying, GKGameModel{
    fileprivate let _players: [GKGameModelPlayer] = [Player(player: 0), Player(player: 1)]
    fileprivate var currentPlayer: GKGameModelPlayer?
    fileprivate var board: [BoardCell]
    fileprivate var currentScoreForPlayerOne: Int
    fileprivate var currentScoreForPlayerTwo: Int
    
    /// Checks if the current player is player one.
    /// - Returns: True if the current player is player one
    func isPlayerOne()->Bool{
        return currentPlayer?.playerId == _players[0].playerId
    }
    
    func playerOne()->GKGameModelPlayer{
        return _players[0]
    }
    
    func playerTwo()->GKGameModelPlayer{
        return _players[1]
    }
    
    func setActivePlayer(_ player: GKGameModelPlayer){
        currentPlayer = player
    }
    
    /// Checks if it's currently player one's turn.
    /// - Returns: True if player one is active, false otherwise
    func isPlayerOneTurn()->Bool{
        guard let player = activePlayer else {
            return false
        }
        return isPlayerOne(player)
    }
    
    /// Checks if it's currently player two's turn.
    /// - Returns: True if player two is active, false otherwise
    func isPlayerTwoTurn()->Bool{
        return !isPlayerOneTurn()
    }
    
    func makePlayerOneActive(){
        currentPlayer = _players[0]
    }
    
    func makePlayerTwoActive(){
        currentPlayer = _players[1]
    }
    
    func getElementAtBoardLocation(_ index:Int)->BoardCell{
        assert(index < board.count, "Location on board must be less than total elements in array")
        return board[index]
    }
    
    func addPlayerValueAtBoardLocation(_ index: Int, value: PlayerType){
        assert(index < board.count, "Location on board must be less than total elements in array")
        board[index].value = value
    }
    
    @objc func isPlayerOne(_ player: GKGameModelPlayer)->Bool{
        return player.playerId == _players[0].playerId
    }
    
    
    @objc func copy(with zone: NSZone?) -> Any{
        let copy = Board()
        copy.setGameModel(self)
        return copy
    }
    
    required override init() {
        self.currentPlayer = _players[0]
        self.board = []
        self.currentScoreForPlayerOne = 0
        self.currentScoreForPlayerTwo = 0
        
        super.init()
    }
    
    init(gameboard: [BoardCell]){
        self.currentPlayer = _players[0]
        self.board = gameboard
        self.currentScoreForPlayerOne = 0
        self.currentScoreForPlayerTwo = 0
        super.init()
    }
    
    required init(_ board: Board){
        self.currentPlayer =  board.currentPlayer
        self.board = Array(board.board)
        self.currentScoreForPlayerOne = 0
        self.currentScoreForPlayerTwo = 0
        super.init()
    }
    
    @objc var players: [GKGameModelPlayer]?{
       return self._players
    }
    
    var activePlayer: GKGameModelPlayer?{
        return currentPlayer
    }
    
    /// Toggles the current player between player one and player two.
    func togglePlayer(){
        currentPlayer = currentPlayer?.playerId == _players[0].playerId ? _players[1] : _players[0]
    }
    
    func setGameModel(_ gameModel: GKGameModel) {
        if let board = gameModel as? Board{
            self.currentPlayer = board.currentPlayer
            self.board = Array(board.board)
        }
    }
    
    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        var moves:[GKGameModelUpdate] = []
        for (index, _) in self.board.enumerated(){
            if self.board[index].value == .none{
                moves.append(Move(cell: index))
            }
        }
        
        return moves
    }
    
    func unapplyGameModelUpdate(_ gameModelUpdate: GKGameModelUpdate) {
        let move = gameModelUpdate as! Move
        self.board[move.cell].value = .none
        self.togglePlayer()
    }
    
    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        let move = gameModelUpdate as! Move
        self.board[move.cell].value = isPlayerOne() ? .x : .o
        self.togglePlayer()
    
    }

    func getPlayerAtBoardCell(_ gridCoord: BoardCell)->GKGameModelPlayer?{
        return gridCoord.value == .x ? self.players?.first: self.players?.last
    }
    
    func isWin(for player: GKGameModelPlayer) -> Bool {
        let (state, winner) = determineIfWinner()
        if state == .winner && winner?.playerId == player.playerId{
            return true
        }
        
        return false
    }
    
    func isLoss(for player: GKGameModelPlayer) -> Bool {
        let (state, winner) = determineIfWinner()
        if state == .winner && winner?.playerId != player.playerId{
            return true
        }
        
        return false
    }
    
    /// Calculates the heuristic score for a given player's position.
    /// - Parameter player: The player to evaluate
    /// - Returns: A static score based on the current board state
    ///
    /// Scoring heuristic:
    /// - 4 points: Winning position (immediate win)
    /// - 0 points: Losing position (opponent has won)
    /// - 3 points: Blocking position (opponent is one move from winning)
    /// - 2 points: Threatening position (player is one move from winning)
    /// - 1 point: Default position (neutral move)
    func score(for player: GKGameModelPlayer) -> Int {
        // Winning position: highest priority
        if isWin(for: player){
            return 4
        }
        
        // Losing position: lowest score
        if isLoss(for: player){
            return 0
        }
        
        let opponent = isPlayerOne(player) ? playerTwo() : playerOne()
        
        // Blocking opponent's win: second highest priority
        let opponentOneMoveAwayFromWinning = isOneMoveAwayFromWinning(opponent)
        if opponentOneMoveAwayFromWinning{
            return 3
        }
        
        // Creating winning threat: third highest priority
        let playOneMoveAwayFromWinning = isOneMoveAwayFromWinning(player)
        if playOneMoveAwayFromWinning{
            return 2
        }
        
        // Default neutral position
        return 1
    }
    
    /// Checks if a player is one move away from winning.
    /// - Parameter player: The player to check
    /// - Returns: True if the player can win with one more move
    func isOneMoveAwayFromWinning(_ player: GKGameModelPlayer)->Bool {
        
        // Helper closure to check if a line has two of player's marks and one empty cell
        let row_diagonal_Checker = {(row:[BoardCell], playerCell: PlayerType)->Bool in
            let numofPlayerTypes = row.filter{$0.value == playerCell}
            let containsBlankCells = row.filter{$0.value == .none}
        
            if containsBlankCells.count == 0{
                return false
            }
        
            if numofPlayerTypes.count == 2 {
                return true
            }
            return false
        }
        
        let playerCell: PlayerType = isPlayerOne(player) ? .x : .o
        
        // Define all lines to check (rows, columns, diagonals)
        let linesToCheck: [[Int]] = [
            // Rows
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8],
            // Columns
            [0, 3, 6],
            [1, 4, 7],
            [2, 5, 8],
            // Diagonals
            [0, 4, 8],
            [2, 4, 6]
        ]
        
        // Check each line
        for lineIndices in linesToCheck {
            let line = lineIndices.map { board[$0] }
            if row_diagonal_Checker(line, playerCell) {
                return true
            }
        }
        
        return false
    }
    
    /// Determines if there's a winner or if the game is in a draw/playing state.
    /// - Returns: A tuple containing the game state and the winning player (if any)
    func determineIfWinner()->(GameState, GKGameModelPlayer?){
        // Define all winning line combinations (indices in board array)
        let winningLines: [[Int]] = [
            // Rows
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8],
            // Columns
            [0, 3, 6],
            [1, 4, 7],
            [2, 5, 8],
            // Diagonals
            [0, 4, 8],
            [2, 4, 6]
        ]
        
        // Check each winning line
        for line in winningLines {
            let firstCell = board[line[0]]
            let secondCell = board[line[1]]
            let thirdCell = board[line[2]]
            
            // Check if all three cells have the same non-empty value
            if firstCell.value != .none &&
               firstCell.value == secondCell.value &&
               firstCell.value == thirdCell.value {
                guard let winner = getPlayerAtBoardCell(firstCell) else {
                    return (.draw, nil)
                }
                return (.winner, winner)
            }
        }
        
        // Check if board is full (draw condition)
        let foundEmptyCells: [BoardCell] = board.filter{ (gridCoord) -> Bool in
            return gridCoord.value == .none
        }
        
        if foundEmptyCells.isEmpty{
            return (.draw, nil)
        }
        
        return (.playing, nil)
    }
}
