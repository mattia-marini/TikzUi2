//
//  ContentView.swift
//  TikzUi
//
//  Created by Mattia Marini on 30/03/24.
//

import SwiftUI

struct ContentView: View {
    @State var tool = "Selection"
    
    var body: some View {
        VStack(alignment: .center){
            Text(tool)
            Renderer(tool: $tool)
        }
    }
}

/*
 #Preview {
 ContentView()
 }
 */
