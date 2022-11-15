//
//  CardGame.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/2.
//

import Foundation

enum Rank: Int, CaseIterable, Comparable {
    case Three=1, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace, Two
    
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum Suit: Int, CaseIterable, Comparable {
    case Club=1, Diamond, Heart, Spade
    
    static func < (lhs: Suit, rhs: Suit) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum Strategy {
    case Random, LowestFirst, HighestFirst
}

//MARK: 牌型定義
enum HandType: Int {
    case Invalid=0, Single, Pair, ThreeOfAKind, Straight, Flush, FullHouse, FourOfAKind, StraightFlush, RoyalFlush
    
    init(_ cards: Stack) {
        var returnType: Self = .Invalid
        
        if cards.count == 1 {
            returnType = .Single
        }
        
        if cards.count == 2 {
            if cards[0].rank == cards[1].rank {
                returnType = .Pair
            }
        }
        
        if cards.count == 3 {
            if cards[0].rank == cards[1].rank && 
            cards[0].rank == cards[2].rank {
                returnType = .ThreeOfAKind
            }
        }
        
        //出牌有5張時
        if cards.count == 5 {
            //先把牌面數字由大到小排列
            let sortedHand = cards.sortByRank()

            //若第二三四張的三張牌數字相同，而且，第一張等於第四張或是第四張等於第五張
            if (sortedHand[1].rank == sortedHand[2].rank && sortedHand[2].rank == sortedHand[3].rank && (sortedHand[0].rank == sortedHand[3].rank || sortedHand[3].rank == sortedHand[4].rank)) {
                returnType = .FourOfAKind
            }
            
            //若一二張相同且四五張相同，且二三張相同或三四張相同
            if sortedHand[0].rank == sortedHand[1].rank && sortedHand[3].rank == sortedHand[4].rank && (sortedHand[1].rank == sortedHand[2].rank || sortedHand[2].rank == sortedHand[3].rank) {
                returnType = .FullHouse
            }
            
            var isStraight = true
            var isFlush = true
            

            
            for (i, _) in sortedHand.enumerated() {
                if i + 1 < 5 {
                    //如果第一張是Ace, 而前一張減後一張的差不是1，就不是順子
                    if i == 0 && sortedHand[0].rank == .Ace {
                        if ((sortedHand[i].rank.rawValue % 13) - (sortedHand[i + 1].rank.rawValue % 13)) != 1 &&
                            ((sortedHand[i + 1].rank.rawValue % 12) - (sortedHand[i].rank.rawValue % 12)) != 3 {
                            isStraight = false
                        }
                    } else {
                        if ((sortedHand[i].rank.rawValue % 13) - (sortedHand[i + 1].rank.rawValue % 13)) != 1 {
                            isStraight = false
                        }
                    }
                    if sortedHand[i].suit != sortedHand[i + 1].suit {
                        isFlush = false
                    }
                }
            }
            if isStraight {
                returnType = .Straight
            }
            
            if isFlush {
                returnType = .Flush
            }
            
            if isStraight && isFlush {
                returnType = .StraightFlush
            }
            
            if isStraight && sortedHand[4].rank == .Ten {
                returnType = .RoyalFlush
            }
        }
        
        self = returnType
    }
}

//MARK: 卡牌定義
struct Card: Identifiable {
    var rank: Rank
    var suit: Suit
    var selected = false    //預設牌沒有被選到
    var back: Bool = true   //預設蓋牌
    var filename: String {
        if !back {
            //如果不是背面就開牌
            return "\(suit) \(rank)"
        } else {
            return "Back"
        }
        
    }
    //使用圖檔本身的UUID
    var id = UUID()
}





//MARK: 數字比較
//把卡牌取別名stack
typealias Stack = [Card]

extension Stack where Element == Card {
    func sortByRank() -> Self {
        var sortedHand = Stack()
        var remainingCards = self
        
        for _ in 1 ... remainingCards.count {
            var highestCardIndex = 0 //先假設手牌第一張最大
            for (i, _) in remainingCards.enumerated() { // 列舉作為手牌總數
                if i + 1 < remainingCards.count { //當前+1的張數小於總張數時才比較牌
                    if remainingCards[i + 1].rank >
                        remainingCards[highestCardIndex].rank ||
                        (remainingCards[i + 1].rank == remainingCards[highestCardIndex].rank &&
                         remainingCards[i + 1].suit > remainingCards[highestCardIndex].suit) {
                            highestCardIndex = i + 1
                        }
                }
            }
            //不斷檢查手牌的最大張再依序加入新的陣列
            let highestCard = remainingCards.remove(at: highestCardIndex)
            sortedHand.append(highestCard)
        }
//        print(sortedHand)
        return sortedHand
    }
}

//MARK: 玩家定義
struct Player: Identifiable, Equatable {
    var cards = Stack()
    var playerName = ""
    var playerIsMe = false
    var activePlayer = false
    var playStyle: Strategy = .Random //出牌策略
    var id = UUID()
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Deck {
    private var cards = Stack()
    
    mutating func createFullDeck() {
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
    }
    
    mutating func shuffle() {
        cards.shuffle()
    }
    
    mutating func drawCard() -> Card {
        //抽牌的同時移除陣列最後元素/牌
        return cards.removeLast()
    }
    
    func cardsRemaining() -> Int {
        return cards.count
    }
}

struct DiscardHand: Identifiable {
    var hand: Stack
    var handOwner: Player
    var id = UUID()
}


//MARK: 遊戲邏輯
struct BigTwo {
    private(set) var discardedHands = [DiscardHand]()
    private(set) var players: [Player]
    
//    private var activePlayer: Player {
//        var player = Player()
//        
//        if let activePlayerIndex = players.firstIndex(where: { $0.activePlayer == true}) {
//            player = players[activePlayerIndex]
//        } else {
//            if let humanIndex = players.firstIndex(where: { $0.playerIsMe == true}) {
//                player = players[humanIndex]
//            }
//        }
//        return player
//    }
    
    init() {
        let opponents = [
            Player(playerName: "CPU1"),
            Player(playerName: "CPU2", playStyle: .HighestFirst),
            Player(playerName: "CPU3", playStyle: .LowestFirst)
        ]
        
        players = opponents
        players.append(Player(playerName: "You", playerIsMe: true))
        
        var deck = Deck()
        deck.createFullDeck()
        deck.shuffle()
        
        //隨機配置玩家順序以配牌
        let randomStartingPlayerIndex = Int(arc4random()) % players.count
        
        //牌堆還有牌才抽
        while deck.cardsRemaining() > 0 {
            for p in randomStartingPlayerIndex...randomStartingPlayerIndex + (players.count - 1) {
                let i = p % players.count // loop 0,1,2,3,0,1,2,3,0,1,2,3...
                var card = deck.drawCard() //從牌堆抽出牌
                if players[i].playerIsMe {
                    card.back = false
                }
                players[i].cards.append(card) //發牌給玩家
            }
        }
    }
    
    //舊select
//    mutating func select(_ card: Card, in player: Player) {
//        if let cardIndex = player.cards.firstIndex(where: { $0.id == card.id }) {
//            if let playerIndex = players.firstIndex(where: { $0.id == player.id }) {
//                players[playerIndex].cards[cardIndex].selected.toggle()
//            }
//        }
//    }
    
    
    //新select，讓function可以 for loop
    //將mainview選到的牌id，同時標記到相同玩家手牌中的牌id，彼此同步
    mutating func select(_ cards: Stack, in player: Player) {
        for i in 0 ... cards.count - 1 {
            let card = cards[i]
            if let cardIndex = player.cards.firstIndex(where: { $0.id == card.id }) {
                if let playerIndex = players.firstIndex(where: { $0.id == player.id }) {
                    //選到的牌selected打開變成true
                    players[playerIndex].cards[cardIndex].selected.toggle()
                }
            }
        }
    }

    //出牌
    mutating func playSelectedCard(of player: Player) {
        if let playerIndex = players.firstIndex(where: { $0.id == player.id }) { //核對玩家id
            var playerHand = players[playerIndex].cards.filter{ $0.selected == true } //選好的牌篩出來
            let remainingCards = players[playerIndex].cards.filter { $0.selected == false } //剩下的牌另外篩
            print("目前玩家:", player.playerName)
            print("出牌張數:", playerHand.count)
            
            //玩家所選到要出的牌每張都翻開
            for i in 0 ... playerHand.count-1 {
                playerHand[i].back = false
            }
            discardedHands.append(DiscardHand(hand: playerHand, handOwner: player))
            players[playerIndex].cards = remainingCards
        }
    }
    
    //換下一家出牌
    mutating func getNextPlayerFromCurrent() -> Player {
        var nextActivePlayer = Player()

        if let activePlayerIndex = players.firstIndex(where: { $0.activePlayer == true }) {
            let nextPlayerIndex = ((activePlayerIndex + 1) % players.count) //用餘數把index的範圍限定在0..3
            nextActivePlayer = players[nextPlayerIndex]
            //停止目前玩家
            players[activePlayerIndex].activePlayer = false
        }
        //返回下一家出牌
        return nextActivePlayer
    }

    
    //驅動應該出牌的玩家
    mutating func activatePlayer(_ player: Player) {
        if let playerIndex = players.firstIndex(where: { $0.id == player.id }) {
            players[playerIndex].activePlayer = true
            
            //如果該出牌的不是玩家，就要換ai處理出牌(這裡移動到 maniView 自動處理)
//            if !activePlayer.playerIsMe {
//                let cpuHand = getCPUHand(of: activePlayer)
//                if cpuHand.count > 0 {
//                    for i in 0...cpuHand.count - 1 {
//                        //標記要出的牌，出牌同時要從電腦手牌刪除，且放到檯面上
//                        select(cpuHand[i], in: activePlayer)
//                    }
//                    playSelectedCard(of: activePlayer)
//                }
//            }
        }
    }
    
    //找到手上有梅花3的玩家，回傳成第一個出牌
    func findStartingPlayer() -> Player {
        var startingPlayer: Player!
        for aPlayer in players {
            if aPlayer.cards.contains(where: { $0.rank == .Three && $0.suit == .Club}) {
                startingPlayer = aPlayer
            }
        }
        return startingPlayer
    }
    
    //MARK: 出牌ai
    func getCPUHand(of player: Player) -> Stack {
        //先預設沒有這些重複數字的牌型，有再另外開啟
        var pairExist = false, threeExist = false, fourExist = false, fullHouseExist = false, straightExist = false, flushExist = false
        
        
        var rankCount = [Rank : Int]()
        var suitCount = [Suit : Int]()
        
        let playerCardsByRank = player.cards.sortByRank()
        
        //計算手牌，數字重複+1，花色多一種就+1
        for card in playerCardsByRank {
            if rankCount[card.rank] != nil {
                rankCount[card.rank]! += 1
            } else {
                rankCount[card.rank] = 1
            }
            
            if suitCount[card.suit] != nil {
                suitCount[card.suit]! += 1
            } else {
                suitCount[card.suit] = 1
            }
        }
        
        //做兩個變數容納重複牌的組合
        var cardsRankCount1 = 1
        var cardsRankCount2 = 1
        
        for rank in Rank.allCases {
            var thisRankCount = 0
            
            //如果存放重複牌的陣列有牌，就放到當前thisRankCount
            if rankCount[rank] != nil {
                thisRankCount = rankCount[rank]!
            } else {
                continue
            }
            
            //檢查有沒有新的重複數字組合大於第一個重複組合，決定有無牌型 pair, three, four, fullhouse
            if thisRankCount > cardsRankCount1 {
                if cardsRankCount1 != 1 {
                    //如果有新重複數字牌比較大，就把第一組放到count2, 把新的放到count1
                    cardsRankCount2 = cardsRankCount1
                }
                cardsRankCount1 = thisRankCount
            } else if thisRankCount > cardsRankCount2 {
                cardsRankCount2 = thisRankCount
            }
            
            //有一個數字重複的時候
            pairExist = cardsRankCount1 > 1 //比一張多是一對
            threeExist = cardsRankCount1 > 2 //比兩張多是三條
            fourExist = cardsRankCount1 > 3 //比三張多是四條
            fullHouseExist = cardsRankCount1 > 2 && cardsRankCount2 > 1 // 3+2= 葫蘆
            
            if straightExist {
                continue //如果沒有順子就跳過
            } else {
                straightExist = true //如果有就往下做檢查
            }
            //數連續五張牌
            for i in 0 ... 4 {
                var rankRawValue = 1
                //如果是rank小於10的牌
                if rank <= Rank.Ten { 
                    rankRawValue = rank.rawValue + i
                } else if rank >= Rank.Ace {
                    //如果牌有rank是Ace:rawValue 或是 2:rawValue=12
                    rankRawValue = (rank.rawValue + i) % 13
                    // 23456 -> 12, 13, 14, 15, 16
                    // 12, (12+1)%13=0,(13+1)%13=1,(14+1)%13=2,(15+1)%13=3
                    if rankRawValue == 0 {
                        rankRawValue = 13
                    }
                }
                //如果存在連續五個數字
                if rankCount[Rank(rawValue: rankRawValue)!] != nil {
                    //順子成立條件：straightExist為真且rankRawValue>0
                    straightExist = straightExist && rankCount[Rank(rawValue: rankRawValue)!]! > 0
                } else {
                    straightExist = false
                }
            }
            
            //花色檢查，同一花色有五張就成立同花
            for suit in Suit.allCases {
                var thisSuitCount = 0
                
                if suitCount[suit] != nil {
                    thisSuitCount = suitCount[suit]!
                }
                flushExist = thisSuitCount > 5
            }
        }
        
        // Singles
        var validHands = combinations(player.cards, k: 1)
        
        // Pairs
        if pairExist {
            var possibleCombination = Stack()
            for card in playerCardsByRank {
                if rankCount[card.rank]! > 1 {
                    possibleCombination.append(card)
                }
            }
            let possibleHands = combinations(possibleCombination, k: 2)
            for i in 0 ..< possibleHands.count {
                if HandType(possibleHands[i]) != .Invalid {
                    validHands.append(possibleHands[i])
                }
            }
        }
        
        // Three of A Kind
        if threeExist {
            var possibleCombination = Stack()
            for card in playerCardsByRank {
                if rankCount[card.rank]! > 2 {
                    possibleCombination.append(card)
                }
            }
            let possibleHands = combinations(possibleCombination, k: 3)
//            print("possibleCombination", possibleCombination.count)
//            print("possibleHands", possibleHands.count)
            for i in 0 ..< possibleHands.count { //fix 11/8
                if HandType(possibleHands[i]) != .Invalid {
                    validHands.append(possibleHands[i])
                }
            }
        }
        
        // Four of a Kind, Flush, Straight, FullHouse, 屬於五張牌的牌型一起判斷
        if fourExist || flushExist || straightExist || fullHouseExist {
            var possibleCombination = Stack()
            for card in playerCardsByRank {
                if (fullHouseExist && rankCount[card.rank]! > 1) ||
                    (fourExist && rankCount[card.rank]! > 3) ||
                    (flushExist && suitCount[card.suit]! > 4) ||
                    straightExist {
                    possibleCombination.append(card)
                }
            }
            let possibleHands = combinations(possibleCombination, k: 5)
            for i in 0 ..< possibleHands.count {
                if HandType(possibleHands[i]) != .Invalid {
                    validHands.append(possibleHands[i])
                }
            }
        }
        
        var sortedHandsByScore = sortHandsByScore(validHands) //降序排列
        var returnHand = Stack()
        
        if player.playStyle == .Random {
            sortedHandsByScore = sortedHandsByScore.shuffled()
        }
        
        if player.playStyle == .HighestFirst {
            sortedHandsByScore = sortedHandsByScore.reversed()
        }
        
        
        //手牌中的出牌必須比上一手大才能出
        for hand in sortedHandsByScore {
            if playable(hand, of: player) {
                returnHand = hand
            }
            
            //直接套playble邏輯，下面可以省略
//            if let lastDiscardHand = discardedHands.last { //是不是第一張出牌？
//                //在這裏比較PC手上的牌有沒有比檯面大
//                if (handScore(hand) > handScore(lastDiscardHand.hand) &&
//                    hand.count == lastDiscardHand.hand.count) ||
//                    (player.id == lastDiscardHand.handOwner.id) {
//                    returnHand = hand
//                    break
//                }
//            } else { // 第一次出牌必須是梅花三
//                if hand.contains(where: {$0.rank == Rank.Three && $0.suit == Suit.Club}) {
//                    returnHand = hand
//                    break
//                }
//            }
        }
//        print(returnHand)
        return returnHand
    }
    
    //判定人類玩家可否出牌
    func playable(_ hand: Stack, of player: Player) -> Bool {
        var playable = false
        //是不是第一張出牌？
        if let lastDiscardHand = discardedHands.last {
            //比較玩家手上的牌要比檯面大且牌數要相等
            //或者玩家id與上次出牌者id相同（電腦都比玩家小）
            if (handScore(hand) > handScore(lastDiscardHand.hand) &&
                hand.count == lastDiscardHand.hand.count) ||
                (player.id == lastDiscardHand.handOwner.id) {
                playable = true
            }
        } else { // 第一次出牌的梅花三
            if hand.contains(where: { $0.rank == Rank.Three && $0.suit == Suit.Club }) {
                playable = true
            }
        }
        return playable
    }
    
    //牌型計分整理
    func sortHandsByScore(_ unsortedHands: [Stack]) -> [Stack] {
        var sortedHands = [Stack]()
        var remainingHands = unsortedHands
        
        for _ in 1 ... unsortedHands.count {
            var highestHandIndex = 0
            for i in 0 ... unsortedHands.count {
                if (i + 1) < remainingHands.count {
                    if handScore(remainingHands[i + 1]) > handScore(remainingHands[highestHandIndex]) {
                        highestHandIndex = i + 1
                    }
                }
            }
            sortedHands.append(remainingHands[highestHandIndex])
            remainingHands.remove(at: highestHandIndex)
        }
        return sortedHands
    }
    
    //牌型比較，用點數計算
    func handScore(_ hand: Stack) -> Int {
        var score = 0

        for i in 0...hand.count - 1 {
            let suitScore = hand[i].suit.rawValue

            if HandType(hand) == .Straight {
                if i < 2 && hand[i].rank == .Ace { //ace開頭的順子最小
                    score += 1111 + suitScore
                }
            } else {
                if hand[i].rank == .Two { //如果不是順子，2就是最高分
                    score += 5555 + suitScore
                } else {
                    score += ((hand[i].rank.rawValue + 3) * 100) + suitScore
                }
            }

            score += (11111 * HandType(hand).rawValue)
        }
        return score
    }
    
    //對手牌持有的各種牌型組合整理成陣列
    func combinations(_ cardArray: Stack, k: Int) -> [Stack] {
        var sub = [Stack]()
        var ret = [Stack]()
        var next = Stack()
        
        for i in 0 ..< cardArray.count {
            if k == 1 { //K等於1的時候
                var tempHand = Stack() //宣告暫存手牌
                tempHand.append(cardArray[i]) //當前卡牌加入暫存手牌
                ret.append(tempHand) //暫存手牌加入陣列ret
            } else { //如果K>1就叫出sliceArray
                //切出組合k=1時slice陣列只有1張，k=2時slice陣列=2，依此類推，x1=當前第幾張牌，x2=剩下的牌
                sub = combinations(sliceArray(cardArray, x1: i+1, x2: cardArray.count - 1), k: k-1)
                
                for subI in 0 ..< sub.count {
                    next = sub[subI]
                    next.append(cardArray[i])
                    ret.append(next)
                }
            }
        }
//        print(ret)
        return ret
    }
    
    //切出組合用的函式
    func sliceArray(_ cardArray: Stack, x1: Int, x2: Int) -> Stack {
        var sliced = Stack()
        
        if x1 <= x2 { //當前牌數要小於等於剩下的牌數
            for i in x1 ... x2 {
                sliced.append(cardArray[i])
            }
        }
        return sliced
    }
    
}

