//
//  ContentView.swift
//  BigTwo
//
//  Created by So í-hian on 2022/11/2.
//

import SwiftUI
import AVFoundation

//名為MainView的struct，遵守view這個protocol
//view是螢幕直接看到的畫面
struct MainView: View {

    //做好的遊戲邏輯放進來，且被監視
    @ObservedObject var bigTwo = BigTwoGame()
    
    //宣告一個可改變app狀態的state property，用作倒數計時用
    @State private var counter = 0
    
    @State private var buttonText = "Pass"
    @State private var disablePlayButton = false
    @State private var disableResetButton = false
    
    //背景音樂looper
    @State var looper: AVPlayerLooper?

    
    //計時器：每秒一次，在主執行緒執行，common mode與其他事件並行，autoconnetct立即連接執行
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    //動畫 Animation
    @State private var dealt = Set<UUID>() //牌堆UUID的set
    @State private var discard = Set<UUID>() //出牌UUID的set
    
    private func deal(_ card: Card) {
        dealt.insert(card.id) //牌的id都放進去
    }
    
    private func discard(_ card: Card) {
        dealt.remove(card.id) //出掉的牌要把他的id移除
        discard.insert(card.id)
    }
    
    private func dealt(_ card: Card) -> Bool {
        dealt.contains(card.id)
    }
    
    private func discarded(_ card: Card) -> Bool {
        discard.contains(card.id)
    }
    
    //發牌動畫，delay牌出現進入畫面的的時間，參數接收 for in 迴圈
    private func dealAnimation(for card: Card, in player: Player) -> Animation {
        var delay = 0.0
        if let index = player.cards.firstIndex(where: { $0.id == card.id }) {
            //處理每張牌進入畫面的delay時間
            delay = Double(index) * (3 / Double(player.cards.count))
        }
        return Animation.easeInOut(duration: 0.5).delay(delay)
    }
    
    
    //宣告view共用的命名空間
    @Namespace private var dealingNamespace
    
    
    //view這個protocol要求一個body屬性，其描述在畫面上會是什麼樣子
    var body: some View {
        
        //GeometryReader定位計算電腦手牌與玩家手牌相對位置
        GeometryReader { geo in
            ZStack {
                Image("Background").resizable().edgesIgnoringSafeArea(.all)
                //MARK: 電腦手牌
                VStack {
                    ForEach(bigTwo.players) { player in
                        if !player.playerIsMe {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: -50)]) {
                                ForEach(player.cards) { card in
                                    //抽牌或出牌時使用動畫
                                    if dealt(card) || discarded(card) {
                                        CardView(card: card)
                                            .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                                        //指定共用的id和命名空間
                                    }
                                }
                            }
                            //配置電腦手牌高度
                            .frame(height: geo.size.height / 7)
                            //是出牌的玩家才給不透明，否則就讓他透明
                            .opacity(player.activePlayer ? 1 : 0.4)
                            .onAppear {
                                for card in player.cards {
                                    withAnimation(dealAnimation(for: card, in: player)) { //先慢再快
                                        deal(card)
                                    }
                                }
                            }
                        }
                    }
                    
                    //MARK: 出牌區域
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                        deckBody
                        VStack {
                            ZStack { //重疊元件的ZStack
                                ForEach(bigTwo.discardedHands) { discardHand in
                                    //顯示最後出牌者和上次出牌者
                                    let i = bigTwo.discardedHands.firstIndex(where: { $0.id == discardHand.id })
                                    let lastDiscardHand: Bool = (i == bigTwo.discardedHands.count - 1)
                                    let prevDiscardHand: Bool = (i == bigTwo.discardedHands.count - 2)
                                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: -30), count: discardHand.hand.count)) {
                                        ForEach(discardHand.hand) { card in
                                            if discarded(card) {
                                                CardView(card: card)
                                                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                                            }
                                        }
                                    }
                                    //是最後出牌的圖就0.8倍大，不是就0.65
                                    .scaleEffect(lastDiscardHand ? 0.80 : 0.65)
                                    //是最後出的牌就透明度給1，上一次的就給0.4，都不是給0
                                    .opacity(lastDiscardHand ? 1 : prevDiscardHand ? 0.4 : 0)
                                    .offset(y: lastDiscardHand ? 0 : -40)
                                }
                                
                            }
                            //最後出牌判定 lastIndex
                            let lastIndex = bigTwo.discardedHands.count - 1
                            if lastIndex >= 0 {
                                //玩家名字為最後出牌者
                                let playerName = bigTwo.discardedHands[lastIndex].handOwner.playerName
                                //手牌也是最後出牌者的手牌
                                let playerHand = bigTwo.discardedHands[lastIndex].hand
                                //出牌者的牌型辨別
                                let handType = "\(bigTwo.evaluateHand(playerHand))"
                                
                                //依據最後出牌者的手牌狀況顯示訊息
                                if bigTwo.gameOver {
                                    Text("Game Over! \(playerName) wins!")
                                        .font(.largeTitle)
                                        .foregroundColor(.yellow)
                                } else {
                                    //text放進vstack顯示在出牌區域下方
                                    Text("\(playerName): \(handType)")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        //偵測到遊戲結束就停止timer
                        .onChange(of: bigTwo.gameOver) { _ in
                            timer.upstream.connect().cancel()
                        }
                    }
                    
                    //MARK: 玩家手牌
                    let myPlayer = bigTwo.players[3]
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: -76)]) {
                        ForEach(myPlayer.cards) { card in
                            if dealt(card) || discarded(card) {
                                CardView(card: card)
                                //動畫用
                                    .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                                //offset位移重疊卡牌
                                    .offset(y: card.selected ? -30 : 0)
                                    .onTapGesture {
                                        //選牌動畫，先慢再快，速度0.2秒
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            bigTwo.select([card], in: myPlayer)
                                            //                                bigTwo.select(card, in: myPlayer)
                                        }
                                        //選擇的玩家是人類時，選的牌篩出陣列
                                        let selectedCards = bigTwo.players[3].cards.filter { $0.selected == true }
                                        if selectedCards.count > 0 { //如果選的牌大於0張
                                            buttonText = "Play" //文字顯示可出牌
                                            if bigTwo.playable(selectedCards, of: myPlayer) {
                                                disablePlayButton = false //牌比台面大就取消隱藏開關，變成能按
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
                    }
                    .onAppear { //元件開始時觸發動畫
                        for card in myPlayer.cards {
                            withAnimation(dealAnimation(for: card, in: myPlayer)) {
                                deal(card)
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        //MARK: 出牌按鈕
                        Button(buttonText) { //達成能playable條件就能出牌
                            //next player
                            counter = 0
                            //玩家出牌放進陣列
                            let selectedCards = myPlayer.cards.filter { $0.selected == true }
                            if selectedCards.count > 0 { //選的牌有大於零張才可以出牌
                                for card in selectedCards {
                                    withAnimation(.easeInOut) { //套上出牌動畫
                                        discard(card) //出牌用的陣列
                                    }
                                }
                                bigTwo.playSelectedCard(of: myPlayer)
                            }
                        }
                        .disabled(myPlayer.activePlayer ? disablePlayButton : true)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        Spacer()
                        
                        Button("New Game") {
                            BigTwoGame.shared.gameID = UUID()
                        }
                        .disabled(bigTwo.gameOver ? disableResetButton : true)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        Spacer()
                    }
                }
                
                
            }
            //偵測玩家改變
            .onChange(of: bigTwo.activePlayer) { player in
                //如果該出牌的不是玩家
                if !player.playerIsMe {
                    //ai檢查能否出牌
                    let cpuHand = bigTwo.getCPUHand(of: player)
                    if cpuHand.count > 0 { //如果有牌可出
                        bigTwo.select(cpuHand, in: player) //要出的牌選好
                        for card in cpuHand {
                            withAnimation(.easeInOut) { //套上出牌動畫
                                discard(card) //出牌用的陣列
                            }
                        }
                        bigTwo.playSelectedCard(of: player) //出牌
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
            .onAppear { //元件執行時等三秒再開始執行(出牌)，跑發牌動畫的時間
                counter = -3
                
                //MARK: 背景音樂
                let player = AVQueuePlayer()
                let fileUrl = Bundle.main.url(forResource: "CasinoShip_00", withExtension: "mp3")!
                let playerItem = AVPlayerItem(url: fileUrl)
                self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
                //player.play()
            }
        }
    }
    
    //動畫用的牌堆
    var deckBody: some View {
        ZStack {
            ForEach(bigTwo.players) { player in
                ForEach(player.cards.filter{ !dealt($0) }) { card in
                    CardView(card: card)
                        .matchedGeometryEffect(id: card.id, in: dealingNamespace)
                        .transition(AnyTransition.asymmetric(insertion: .opacity, removal: .opacity))
                        //.transition(.opacity)
                }
            }
        }
        .frame(width: 60, height: 90)
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
