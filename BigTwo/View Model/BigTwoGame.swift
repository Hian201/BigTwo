//
//  BigTwoGame.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/2.
//

import Foundation

class BigTwoGame: ObservableObject {
    @Published private var model = BigTwo()
    
    @Published private(set) var activePlayer = Player()
    
    var players: [Player] {
        return model.players
    }
    
    var discardedHands: [DiscardHand] {
        return model.discardedHands
    }
    
    //舊的select
    func select(_ card: Card, in player: Player) {
        model.select(card, in: player)
    }
    
    //新select
//    func select(_ cards: Stack, in player: Player) {
//        model.select(cards, in: player)
//    }
    
    func evaluateHand(_ cards: Stack) -> HandType {
        return HandType(cards)
    }
    
    func getNextPlayer() -> Player {
        model.getNextPlayerFromCurrent()
    }
    
    func activatePlayer(_ player: Player) {
        model.activatePlayer(player)
        //當啟動下一家玩家的時候，不管他是不是第一個出牌的順序都要啟動
        if let activePlayerIndex = players.firstIndex(where: { $0.activePlayer == true }) {
            print("change")
            activePlayer = players[activePlayerIndex]
        }
    }
    
    func findStartingPlayer() -> Player {
        return model.findStartingPlayer()
    }
    
    //拿cpu手牌給onChange用
    func getCPUHand(of player: Player) -> Stack {
        return model.getCPUHand(of: player)
    }
    
    func playSelectedCard(of player: Player) {
        model.playSelectedCard(of: player)
    }
    
    func playable(_ hand: Stack, of player: Player) -> Bool {
        return model.playable(hand, of: player)
    }
}
