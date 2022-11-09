//
//  BigTwoGame.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/2.
//

import Foundation

class BigTwoGame: ObservableObject {
    @Published private var model = BigTwo()
    
    @Published private var activePlayer = Player()
    
    var players: [Player] {
        return model.players
    }
    
    var discardedHands: [DiscardHand] {
        return model.discardedHands
    }
    
//    func select(_ cards: Stack, in player: Player) {
//        model.select(cards, in: player)
//    }
    
    func select(_ card: Card, in player: Player) {
        model.select(card, in: player)
    }
    
    
    func evaluateHand(_ cards: Stack) -> HandType {
        return HandType(cards)
    }
    
    func getNextPlayer() {
        model.getNextPlayerFromCurrent()
    }
    
    func activatePlayer(_ player: Player) {
        model.activatePlayer(player)
        if let activePlayerIndex = players.firstIndex(where: { $0.activePlayer == true}) {
            activePlayer = players[activePlayerIndex]
        }
    }
    
    func findStartingPlayer() -> Player {
        return model.findStartingPlayer()
    }
}
