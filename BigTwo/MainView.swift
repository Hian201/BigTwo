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
    
    //宣告一個可改變app狀態的state property，用作倒數計時用
    @State private var counter = 0
    
    @State private var buttonText = "Pass"
    @State private var disablePlayButton = false
    
    //計時器：每秒一次，在主執行緒執行，common mode與其他事件並行，autoconnetct立即連接執行
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                        //是出牌的玩家才給不透明，否則就讓他透明
                        .opacity(player.activePlayer ? 1 : 0.2)
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
                                let lastDiscardHand: Bool = (i == bigTwo.discardedHands.count - 1)
                                let prevDiscardHand: Bool = (i == bigTwo.discardedHands.count - 2)
                                LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: -30), count: discardHand.hand.count)) {
                                    ForEach(discardHand.hand) { card in
                                        CardView(card: card)
                                    }
                                }
                                //是最後出牌的圖就0.8倍大，不是就0.65
                                .scaleEffect(lastDiscardHand ? 0.80 : 0.65)
                                //是最後出的牌就透明度給1，上一次的就給0.4，都不是給0
                                .opacity(lastDiscardHand ? 1 : prevDiscardHand ? 0.4 : 0)
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
                                bigTwo.select([card], in: myPlayer)
//                                bigTwo.select(card, in: myPlayer)
                                //選擇的玩家是人類時，選的牌篩出陣列
                                let selectedCards = bigTwo.players[3].cards.filter { $0.selected == true }
                                if selectedCards.count > 0 { //如果選的牌大於0張
                                    buttonText = "Play" //文字顯示可出牌
                                    if bigTwo.playable(selectedCards, of: myPlayer) {
                                        disablePlayButton = false //牌比台面大就隱藏開關取消，變成能按
                                    } else {
                                        disablePlayButton = true
                                    }
                                } else { //不選牌的情況下可以直接pass
                                    buttonText = "Pass"
                                    disablePlayButton = false
                                }
                            }
                    }
                }
                Button(buttonText) { //達成能playable條件就能出牌
                    //next player
                    counter = 0
                    //玩家出牌放進陣列
                    let selectedCards = myPlayer.cards.filter { $0.selected == true }
                    if selectedCards.count > 0 { //選的牌有大於零張才可以出牌
                        bigTwo.playSelectedCard(of: myPlayer)
                    }
                }
                .disabled(myPlayer.activePlayer ? disablePlayButton : true)
            }
        }
        //偵測玩家改變
        .onChange(of: bigTwo.activePlayer) { player in
            //如果該出牌的不是玩家，就要換ai處理出牌
            if !player.playerIsMe {
                let cpuHand = bigTwo.getCPUHand(of: player)
                if cpuHand.count > 0 {
                    //標記要出的牌，出牌同時要從電腦手牌刪除，且放到檯面上
                    
//                    for i in 0 ... cpuHand.count - 1 {
//                        bigTwo.select(cpuHand[i], in: player)
//                    }
//                    bigTwo.playSelectedCard(of: player)
//                }
                
                bigTwo.select(cpuHand, in: player)
                bigTwo.playSelectedCard(of: player)
                }
            }
        }
        //接收timer每秒發送的value
        .onReceive(timer) { time in
            var nextPlayer = Player()
            print(counter)
            counter += 1
            if counter >= 2 { //計時器兩秒後歸零
                //counter = 0
                if bigTwo.discardedHands.count == 0 { //如果台面上沒牌
                    //找第一個有梅花3的玩家出牌
                    nextPlayer = bigTwo.findStartingPlayer()
                } else { //台面上有牌就換下一家出牌
                    nextPlayer = bigTwo.getNextPlayer()
                }
                bigTwo.activatePlayer(nextPlayer)
                //如果下一家是人不是電腦，就給100秒出牌時間
                if nextPlayer.playerIsMe {
                    counter = -100
                    buttonText = "Pass"
                } else {
                    counter = 0
                }
            }
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
