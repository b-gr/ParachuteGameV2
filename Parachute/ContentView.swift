//
//  ContentView.swift
//  Parachute
//
//  Created by Ben Gresham on 01/02/2026.
//

import SpriteKit
import SwiftUI

#if os(iOS)
import Combine
import CoreMotion
#endif

#if os(macOS)
import AppKit
#endif

private let gameplaySize = CGSize(width: 390, height: 844)

struct ContentView: View {
    @State private var scene: TubeScene
#if os(iOS)
    @State private var nameEntry = ""
    @State private var controlMode: TubeScene.ControlMode = .buttons
    @State private var motionManager = CMMotionManager()
    @State private var uiTick = 0
    private let uiTimer = Timer.publish(every: 1.0 / 15.0, on: .main, in: .common).autoconnect()
#endif

    init() {
        let scene = TubeScene(size: gameplaySize)
        scene.scaleMode = .aspectFit
        _scene = State(initialValue: scene)
    }

    var body: some View {
#if os(iOS)
        let _ = uiTick
#endif
        TimelineView(.animation) { _ in
            ZStack {
                gameView
                    .ignoresSafeArea()
#if os(iOS)
                if scene.isEnteringName {
                    NameEntryOverlay(scene: scene, nameEntry: $nameEntry)
                } else {
                    ControlOverlay(scene: scene, controlMode: $controlMode, uiTick: uiTick)
                }
#endif
            }
        }
        .onAppear {
#if os(iOS)
            nameEntry = scene.currentNameBuffer()
            configureControls(for: controlMode)
#endif
        }
#if os(iOS)
        .onChange(of: controlMode) { newValue in
            configureControls(for: newValue)
        }
        .onReceive(uiTimer) { _ in
            uiTick &+= 1
        }
        .onDisappear {
            stopTiltUpdates()
        }
#endif
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

#if os(iOS)
    private func configureControls(for mode: TubeScene.ControlMode) {
        scene.setControlMode(mode)
        switch mode {
        case .buttons:
            stopTiltUpdates()
            scene.updateTiltAxis(0)
            scene.setButtonInput(left: false, right: false)
        case .tilt:
            startTiltUpdates()
        }
    }

    private func startTiltUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        if motionManager.isDeviceMotionActive { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let axis = max(-1, min(1, CGFloat(motion.gravity.x) * 2.0))
            scene.updateTiltAxis(axis)
        }
    }

    private func stopTiltUpdates() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
#endif
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

private struct ControlOverlay: View {
    let scene: TubeScene
    @Binding var controlMode: TubeScene.ControlMode
    let uiTick: Int
    @State private var leftPressed = false
    @State private var rightPressed = false

    var body: some View {
        let _ = uiTick
        VStack {
            if scene.isReady || scene.isShowingScores {
                Picker("Controls", selection: $controlMode) {
                    Text("Buttons").tag(TubeScene.ControlMode.buttons)
                    Text("Tilt").tag(TubeScene.ControlMode.tilt)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Spacer()

            if scene.isReady || scene.isShowingScores {
                Button("Start") {
                    leftPressed = false
                    rightPressed = false
                    applyButtons()
                    scene.handlePrimaryAction()
                }
                .font(.system(size: 20, weight: .semibold))
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(.black.opacity(0.7), in: Capsule())
                .foregroundStyle(.white)
                .padding(.bottom, 32)
            } else if controlMode == .buttons && !scene.isReady && !scene.isShowingScores {
                HStack(spacing: 80) {
                    HoldButton(systemName: "arrow.left.circle.fill") { pressed in
                        leftPressed = pressed
                        applyButtons()
                    }
                    HoldButton(systemName: "arrow.right.circle.fill") { pressed in
                        rightPressed = pressed
                        applyButtons()
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onChange(of: controlMode) { newValue in
            if newValue == .tilt {
                leftPressed = false
                rightPressed = false
                applyButtons()
            }
        }
    }

    private func applyButtons() {
        guard controlMode == .buttons else { return }
        scene.setButtonInput(left: leftPressed, right: rightPressed)
    }
}

private struct HoldButton: View {
    let systemName: String
    let onPressChanged: (Bool) -> Void
    @State private var isPressed = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(.white)
            .padding(12)
            .background(.black.opacity(0.35), in: Circle())
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPressChanged(true)
                        }
                    }
                    .onEnded { _ in
                        if isPressed {
                            isPressed = false
                            onPressChanged(false)
                        }
                    }
            )
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
