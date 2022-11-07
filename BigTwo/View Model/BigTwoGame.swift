//
//  BigTwoGame.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/2.
//

import Foundation

class BigTwoGame: ObservableObject {
    @Published private var model = BigTwo()
    
    var players: [Player] {
        return model.players
    }
    
    var discardedHands: [DiscardHand] {
        return model.discardedHands
    }
    
    func select(_ card: Card, in player: Player) {
        model.select(card, in: player)
    }
    
    func evaluateHand(_ cards: Stack) -> HandType {
        return HandType(cards)
    }
    
    func activateNextPlayer() {
        model.activateNextPlayerFromCurrent()
    }
    
    func activatePlayer(_ player: Player) {
        model.activatePlayer(player)
    }
    
    func findStartingPlayer() -> Player {
        return model.findStartingPlayer()
    }
}
