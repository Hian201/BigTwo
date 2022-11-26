//
//  Playsound.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/16.
//

import AVFoundation

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(filePath: path))
        } catch {
            print("error: Could not find and play the sound file")
        }
    }
}

//class effect: ObservableObject {
//    var player = AVAudioPlayer()
//    
//    init(name: String, type: String, volume: Float = 1) {
//        if let url = Bundle.main.url(forResource: name, withExtension: type) {
//            print("success audio file: \(name)")
//            do {
//                player = try AVAudioPlayer(contentsOf: url)
//                player.prepareToPlay()
//                player.setVolume(volume, fadeDuration: 0)
//            } catch {
//                print("error getting audio \(error.localizedDescription)")
//            }
//        }
//        
//    }
//    
//    func toggle() {
//        if player.isPlaying {
//            player.pause()
//        } else {
//            player.play()
//        }
//    }
//}
