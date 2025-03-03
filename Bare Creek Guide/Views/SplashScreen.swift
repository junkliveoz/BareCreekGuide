//
//  SplashScreen.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Image("BareCreek-Open")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Bare Creek")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    Text("Bike Park")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sydney, NSW")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("AccentColor"))
                }
                
                .shadow(color: .black, radius: 6)
            }
            .onAppear {
                // Show splash screen for 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
