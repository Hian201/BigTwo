//
//  SplashScreenView.swift
//  BigTwo
//
//  Created by yixuan on 2022/11/16.
//

import SwiftUI

struct SplashScreenView: View {
    @State var isActive : Bool = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            MainView()
        } else {
            ZStack {
                Image("Background").resizable().edgesIgnoringSafeArea(.all)
                VStack {
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width:128, height: 128)
                    
                    Text("Big Two")
                        .font(Font.custom("Impact", size: 50))
                        .foregroundColor(.yellow.opacity(0.80))
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.1)) {
                        self.size = 0.9
                        self.opacity = 1.00
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
        
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
