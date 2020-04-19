//
//  ContentView.swift
//  windmill
//
//  Created by Liam  on 2020-04-17.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.00, green: 0.72, blue: 0.58, opacity: 1.00).edgesIgnoringSafeArea(.all)
            VStack {
                Text("welcome")
                    .font(Font.custom("Pacifico-Regular", size: 40))
                    .bold()
                    .foregroundColor(.white)
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
