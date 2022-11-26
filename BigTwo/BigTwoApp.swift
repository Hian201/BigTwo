//
//  BigTwoApp.swift
//  BigTwo
//
//  Created by So í-hian on 2022/11/2.
//

import SwiftUI

@main
struct BigTwoApp: App {
    @StateObject var appState = BigTwoGame.shared 
    
    var body: some Scene {
        WindowGroup {
            //MainView()
            SplashScreenView().id(appState.gameID)
        }
    }
}
