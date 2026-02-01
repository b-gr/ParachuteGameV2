//
//  ParachuteApp.swift
//  Parachute
//
//  Created by Ben Gresham on 01/02/2026.
//

import SwiftUI

private let gameplaySize = CGSize(width: 390, height: 844) // Baseline game canvas size for window defaults.

/// App entry point that hosts the game view.
@main
struct ParachuteApp: App {
    /// Builds the main window scene for the game.
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
