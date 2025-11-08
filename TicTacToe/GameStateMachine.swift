//
//  GameStateMachine.swift
//  TicTacToe
//
//  Created by Keith Elliott on 7/3/16.
//  Copyright © 2016 GittieLabs. All rights reserved.
//

import Foundation
import GameplayKit
import SpriteKit

@MainActor
class StartGameState: GKState{
    var scene: GameScene?
    var winningLabel: SKNode!
    var resetNode: SKNode!
    var boardNode: SKNode!
    
    init(scene: GameScene){
        self.scene = scene
        super.init()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == ActiveGameState.self
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        resetGame()
        self.stateMachine?.enter(ActiveGameState.self)
    }
    
    func resetGame(){
        let top_left: BoardCell  = BoardCell(value: .none, node: "//*top_left")
        let top_middle: BoardCell = BoardCell(value: .none, node: "//*top_middle")
        let top_right: BoardCell = BoardCell(value: .none, node: "//*top_right")
        let middle_left: BoardCell = BoardCell(value: .none, node: "//*middle_left")
        let center: BoardCell = BoardCell(value: .none, node: "//*center")
        let middle_right: BoardCell = BoardCell(value: .none, node: "//*middle_right")
        let bottom_left: BoardCell = BoardCell(value: .none, node: "//*bottom_left")
        let bottom_middle: BoardCell = BoardCell(value: .none, node: "//*bottom_middle")
        let bottom_right: BoardCell = BoardCell(value: .none, node: "//*bottom_right")
        
        boardNode = self.scene?.childNode(withName: "//Grid") as? SKSpriteNode
        
        winningLabel = self.scene?.childNode(withName: "winningLabel")
        winningLabel.isHidden = true
        
        resetNode = self.scene?.childNode(withName: "Reset")
        resetNode.isHidden = true
        
        
        let board = [top_left, top_middle, top_right, middle_left, center, middle_right, bottom_left, bottom_middle, bottom_right]
        
        self.scene?.gameBoard = Board(gameboard: board)
        
        self.scene?.enumerateChildNodes(withName: "//grid*") { (node, stop) in
            if let node = node as? SKSpriteNode{
                node.removeAllChildren()
            }
        }
    }
}

@MainActor
class EndGameState: GKState{
    var scene: GameScene?
    
    init(scene: GameScene){
        self.scene = scene
        super.init()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == StartGameState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        updateGameState()
    }
    
    func updateGameState(){
        let resetNode = self.scene?.childNode(withName: "Reset")
        resetNode?.isHidden = false
    }
}

@MainActor
class ActiveGameState: GKState{
    var scene: GameScene?
    var waitingOnPlayer: Bool
    
    init(scene: GameScene){
        self.scene = scene
        waitingOnPlayer = false
        super.init()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == EndGameState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        waitingOnPlayer = false
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard scene != nil, scene?.gameBoard != nil else {
            return
        }
        
        if !waitingOnPlayer{
            waitingOnPlayer = true
            updateGameState()
        }
    }
    
    func updateGameState(){
        guard let scene = scene, let gameBoard = scene.gameBoard else {
            return
        }
        
        let (state, winner) = gameBoard.determineIfWinner()
        if state == .winner{
            let winningLabel = self.scene?.childNode(withName: "winningLabel")
            winningLabel?.isHidden = true
            guard let winner = winner, let winningPlayer = gameBoard.isPlayerOne(winner) ? "1" : "2" as String? else {
                return
            }
            if let winningLabel = winningLabel as? SKLabelNode,
                let player1_score = self.scene?.childNode(withName: "//player1_score") as? SKLabelNode,
                let player2_score = self.scene?.childNode(withName: "//player2_score") as? SKLabelNode{
                winningLabel.text = "Player \(winningPlayer) wins!"
                winningLabel.isHidden = false
                
                if winningPlayer == "1"{
                    if let score = Int(player1_score.text ?? "0") {
                        player1_score.text = "\(score + 1)"
                    }
                }
                else{
                    if let score = Int(player2_score.text ?? "0") {
                        player2_score.text = "\(score + 1)"
                    }
                }
                
                self.stateMachine?.enter(EndGameState.self)
                waitingOnPlayer = false
            }
        }
        else if state == .draw{
            let winningLabel = self.scene?.childNode(withName: "winningLabel")
            winningLabel?.isHidden = true
            
            
            if let winningLabel = winningLabel as? SKLabelNode{
                winningLabel.text = "It's a draw"
                winningLabel.isHidden = false
            }
            self.stateMachine?.enter(EndGameState.self)
            waitingOnPlayer = false
        }

        else if gameBoard.isPlayerTwoTurn(){
            //AI moves
            self.scene?.isUserInteractionEnabled = false
            
            guard let scene = scene, let gameBoard = scene.gameBoard else {
                return
            }
                
            Task {
                let aiMove = await withCheckedContinuation { continuation in
                    Task.detached {
                        scene.ai.gameModel = gameBoard
                        let move = scene.ai.bestMoveForActivePlayer() as? Move
                        continuation.resume(returning: move)
                    }
                }
                
                guard let move = aiMove else {
                    await MainActor.run {
                        self.scene?.isUserInteractionEnabled = true
                        self.waitingOnPlayer = false
                    }
                    return
                }
                
                let strategistTime = CFAbsoluteTimeGetCurrent()
                let delta = CFAbsoluteTimeGetCurrent() - strategistTime
                let aiTimeCeiling: TimeInterval = 1.0
                
                let delay = min(aiTimeCeiling - delta, aiTimeCeiling)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                await MainActor.run {
                    guard let cellNode = self.scene?.childNode(withName: gameBoard.getElementAtBoardLocation(move.cell)?.node ?? "") as? SKSpriteNode else {
                        self.scene?.isUserInteractionEnabled = true
                        self.waitingOnPlayer = false
                        return
                    }
                    let circle = SKSpriteNode(imageNamed: "O_symbol")
                    circle.size = CGSize(width: 75, height: 75)
                    cellNode.addChild(circle)
                    _ = gameBoard.addPlayerValueAtBoardLocation(move.cell, value: .o)
                    gameBoard.togglePlayer()
                    self.waitingOnPlayer = false
                    self.scene?.isUserInteractionEnabled = true
                }
            }
        }
        else{
            self.waitingOnPlayer = false
            self.scene?.isUserInteractionEnabled = true
        }
    }
}
