//
//  ContentView.swift
//  BigTwo
//
//  Created by So í-hian on 2022/11/2.
//

import SwiftUI

struct MainView: View {
    //做好的遊戲邏輯放進來，且被監視
    @ObservedObject var bigTwo = BigTwoGame()
    

    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ForEach(bigTwo.players) { player in
                    if !player.playerIsMe {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: -50)]) {
                            ForEach(player.cards) {
                                card in
                                CardView(card: card)
                            }
                        }
                        //配置電腦手牌高度
                        .frame(height: geo.size.height / 7)
                    }
                }
                //出牌區域
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.green)
                    VStack {
                        ZStack {
                            ForEach(bigTwo.discardedHands) { discardHand in
                                //顯示最後出牌者和上次出牌者
                                let i = bigTwo.discardedHands.firstIndex(where: { $0.id == discardHand.id })
                                let lastDiscardHand: Bool = ( i == bigTwo.discardedHands.count - 1)
                                let preDiscardHand: Bool = ( i == bigTwo.discardedHands.count - 2)
                                LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: -30), count: discardHand.hand.count)) {
                                    ForEach(discardHand.hand) { card in
                                        CardView(card: card)
                                    }
                                }
                                //是最後出牌的圖就0.8倍大，不是就0.65
                                .scaleEffect(lastDiscardHand ? 0.80 : 0.65)
                                //是最後出的牌就透明度給1，上一次的就給0.4，都不是給0
                                .opacity(lastDiscardHand ? 1 : preDiscardHand ? 0.4 : 0)
                                .offset(y: lastDiscardHand ? 0 : -40)
                            }
                            
                        }
                        //lastIndex=最後出牌者
                        let lastIndex = bigTwo.discardedHands.count - 1
                        if lastIndex >= 0 {
                            //玩家名字為最後出牌者
                            let playerName = bigTwo.discardedHands[lastIndex].handOwner.playerName
                            //手牌也是最後出牌者的手牌
                            let playerHand = bigTwo.discardedHands[lastIndex].hand
                            //出牌者的牌型辨別
                            let handType = "\(bigTwo.evaluateHand(playerHand))"
                            //text放進vstack顯示在出牌區域下方
                            Text("\(playerName): \(handType)")
                        }
                    }
                }
                    
                //玩家手牌
                let myPlayer = bigTwo.players[3]
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: -76)]) {
                    ForEach(myPlayer.cards) { card in
                        CardView(card: card)
                        //offset位移重疊卡牌
                            .offset(y: card.selected ? -30 : 0)
                            .onTapGesture {
                                bigTwo.select(card, in: myPlayer)
                            }
                    }
                }
                    
                
                Button("Next") {
                    //next player
                    bigTwo.getNextPlayer()
                }
            }
        }
        .onAppear() {
            print("On Appear")
            let playerWithLowCard = bigTwo.findStartingPlayer()
            bigTwo.activatePlayer(playerWithLowCard)
            print(playerWithLowCard.playerName)
            print(bigTwo.discardedHands)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

//底層全區域
struct CardView: View {
    let card: Card
    var body: some View {
        Image(card.filename)
            .resizable()
            .aspectRatio(2/3, contentMode: .fit)
    }
}
