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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: -76)]) {
                            ForEach(player.cards) {
                                card in
                                CardView(card: card)
                            }
                        }
                        //配置電腦手牌高度
                        .frame(height: geo.size.height / 6)
                    }
                }
                //出牌區域
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.green)
                    ForEach(bigTwo.discardedHands) { discardHand in
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: -30), count: discardHand.hand.count)) {
                            ForEach(discardHand.hand) { card in
                                CardView(card: card)
                            }
                        }
                        .scaleEffect(0.80)
                    }
                    
                    let playerHand = bigTwo.players[3].cards.filter({$0.selected == true})
                    let handType = "\(bigTwo.evaluateHand(playerHand))"
                    Text(handType).font(.title)
                }
                
                
                //玩家手牌
                let myPlayer = bigTwo.players[3]
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: -76)]) {
                    ForEach(myPlayer.cards) { card in
                        CardView(card: card)
                            .offset(y: card.selected ? -30 : 0)
                            .onTapGesture {
                                bigTwo.select(card, in: myPlayer)
                            }
                    }
                }
                
                Button("Next") {
                    //next player
                    bigTwo.activateNextPlayer()
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
