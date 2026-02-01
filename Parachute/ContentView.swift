//
//  ContentView.swift
//  Parachute
//
//  Created by Ben Gresham on 01/02/2026.
//

import SpriteKit
import SwiftUI

#if os(macOS)
import AppKit
#endif

private let gameplaySize = CGSize(width: 390, height: 844)

struct ContentView: View {
    @State private var scene: TubeScene
#if os(iOS)
    @State private var nameEntry = ""
#endif

    init() {
        let scene = TubeScene(size: gameplaySize)
        scene.scaleMode = .aspectFit
        _scene = State(initialValue: scene)
    }

    var body: some View {
        TimelineView(.animation) { _ in
            ZStack {
                gameView
                    .ignoresSafeArea()
#if os(iOS)
                if scene.isEnteringName {
                    NameEntryOverlay(scene: scene, nameEntry: $nameEntry)
                }
#endif
            }
        }
        .onAppear {
#if os(iOS)
            nameEntry = scene.currentNameBuffer()
#endif
        }
    }

    @ViewBuilder
    private var gameView: some View {
#if os(macOS)
        MacGameView(scene: scene)
            .frame(width: gameplaySize.width, height: gameplaySize.height)
#else
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
#endif
    }
}

#if os(iOS)
private struct NameEntryOverlay: View {
    let scene: TubeScene
    @Binding var nameEntry: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your name")
                .font(.headline)
                .foregroundStyle(.white)
            TextField("Player", text: $nameEntry)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .onChange(of: nameEntry) { newValue in
                    scene.updateNameBuffer(newValue)
                    let filtered = scene.currentNameBuffer()
                    if filtered != newValue {
                        nameEntry = filtered
                    }
                }
                .onSubmit {
                    scene.submitNameEntry()
                }
                .submitLabel(.done)
            Button("Save Score") {
                scene.submitNameEntry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
        .onAppear {
            nameEntry = scene.currentNameBuffer()
        }
    }
}
#endif

#if os(macOS)
private final class GameView: SKView {
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        scene?.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        scene?.mouseDragged(with: event)
    }

    override func keyDown(with event: NSEvent) {
        scene?.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        scene?.keyUp(with: event)
    }
}

private struct MacGameView: NSViewRepresentable {
    let scene: TubeScene

    func makeNSView(context: Context) -> GameView {
        let view = GameView()
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
#if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
#endif
        view.presentScene(scene)
        return view
    }

    func updateNSView(_ nsView: GameView, context: Context) {
        if nsView.scene !== scene {
            nsView.presentScene(scene)
        }
        if nsView.window?.firstResponder !== nsView {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}
#endif

#Preview {
    ContentView()
}
