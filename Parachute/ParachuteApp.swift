//
//  ParachuteApp.swift
//  Parachute
//
//  Created by Ben Gresham on 01/02/2026.
//

import SwiftUI

private let gameplaySize = CGSize(width: 390, height: 844)

@main
struct ParachuteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
#if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: gameplaySize.width, height: gameplaySize.height)
#endif
    }
}
