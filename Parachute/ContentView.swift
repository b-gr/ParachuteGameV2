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
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

private let gameplaySize = CGSize(width: 390, height: 844) // Baseline game canvas size.

/// Root SwiftUI view that hosts the SpriteKit scene and overlays.
struct ContentView: View {
    /// Persistent game scene instance shared across SwiftUI updates.
    @State private var scene: TubeScene
#if os(iOS)
    /// Name entry buffer for the high-score dialog.
    @State private var nameEntry = ""
    /// Selected control scheme for iOS.
    @State private var controlMode: TubeScene.ControlMode = .buttons
    /// Core Motion manager used for tilt controls.
    @State private var motionManager = CMMotionManager()
    /// UI refresh tick used to reflect scene state changes in overlays.
    @State private var uiTick = 0
    /// Timer that drives lightweight UI refreshes during gameplay.
    private let uiTimer = Timer.publish(every: 1.0 / 15.0, on: .main, in: .common).autoconnect()
#endif

    /// Creates and configures the SpriteKit scene.
    init() {
        let scene = TubeScene(size: gameplaySize)
        scene.scaleMode = .aspectFit
        _scene = State(initialValue: scene)
#if os(iOS)
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
#endif
    }

    /// Renders the game view plus any platform-specific overlays.
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
        .onChange(of: controlMode) { _, newValue in
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
    /// Builds the platform-specific SpriteKit host view.
    private var gameView: some View {
#if os(macOS)
        MacGameView(scene: scene)
            .frame(width: gameplaySize.width, height: gameplaySize.height)
#else
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
#endif
    }

#if os(iOS)
    /// Applies the selected control mode and starts/stops motion updates.
    private func configureControls(for mode: TubeScene.ControlMode) {
        scene.setControlMode(mode)
        switch mode {
        case .buttons:
            stopTiltUpdates()
            scene.updateTiltAxis(0)
            scene.updateJoystickAxis(0)
            scene.setButtonInput(left: false, right: false)
        case .tilt:
            startTiltUpdates()
            scene.updateJoystickAxis(0)
        case .joystick:
            stopTiltUpdates()
            scene.updateTiltAxis(0)
            scene.setButtonInput(left: false, right: false)
        }
    }

    /// Starts device-motion updates and forwards the tilt axis to the scene.
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

    /// Stops device-motion updates when tilt mode is disabled.
    private func stopTiltUpdates() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
#endif
}

#if os(iOS)
/// Overlay for entering a high-score name on iOS.
private struct NameEntryOverlay: View {
    /// Target scene to update with the typed name.
    let scene: TubeScene
    /// Two-way binding for the text field.
    @Binding var nameEntry: String

    /// Builds the name-entry dialog UI.
    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your name")
                .font(.headline)
                .foregroundStyle(.white)
            TextField("Player", text: $nameEntry)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .onChange(of: nameEntry) { _, newValue in
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

/// Overlay that presents control selection and in-game buttons on iOS.
private struct ControlOverlay: View {
    /// Target scene to drive control input.
    let scene: TubeScene
    /// Selected control mode (buttons or tilt).
    @Binding var controlMode: TubeScene.ControlMode
    /// Tick used to refresh overlay state from the scene.
    let uiTick: Int
    /// Whether the left button is currently pressed.
    @State private var leftPressed = false
    /// Whether the right button is currently pressed.
    @State private var rightPressed = false

    /// Renders the control picker, start button, and arrow controls.
    var body: some View {
        let _ = uiTick
        VStack {
            if scene.isReady {
                Picker("Controls", selection: $controlMode) {
                    Text("Buttons").tag(TubeScene.ControlMode.buttons)
                    Text("Joystick").tag(TubeScene.ControlMode.joystick)
                    Text("Tilt").tag(TubeScene.ControlMode.tilt)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .offset(y: -10)
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
            } else if controlMode == .joystick && !scene.isReady && !scene.isShowingScores {
                JoystickControl { axis in
                    scene.updateJoystickAxis(axis)
                }
                .padding(.bottom, 24)
            }
        }
        .onChange(of: controlMode) { _, newValue in
            if newValue == .tilt {
                leftPressed = false
                rightPressed = false
                applyButtons()
                scene.updateJoystickAxis(0)
            } else if newValue != .joystick {
                scene.updateJoystickAxis(0)
            }
        }
    }

    /// Applies the current button state to the scene input.
    private func applyButtons() {
        guard controlMode == .buttons else { return }
        scene.setButtonInput(left: leftPressed, right: rightPressed)
    }
}

/// Press-and-hold button used for directional control.
private struct HoldButton: View {
    /// SF Symbol name for the button glyph.
    let systemName: String
    /// Called whenever the pressed state changes.
    let onPressChanged: (Bool) -> Void
    /// Internal state tracking whether the button is pressed.
    @State private var isPressed = false

    /// Renders the button and handles press gestures.
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

/// Analog left-right joystick control for touch input.
private struct JoystickControl: View {
    /// Called with the normalized horizontal axis (-1...1).
    let onAxisChanged: (CGFloat) -> Void
    @State private var knobOffset: CGSize = .zero

    /// Renders the joystick base and draggable knob.
    var body: some View {
        let radius: CGFloat = 44
        let knobRadius: CGFloat = 20
        ZStack {
            Circle()
                .fill(.black.opacity(0.35))
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .offset(knobOffset)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = max(-radius, min(radius, value.translation.width))
                    let dy = max(-radius, min(radius, value.translation.height))
                    knobOffset = CGSize(width: dx, height: dy)
                    onAxisChanged(dx / radius)
                }
                .onEnded { _ in
                    knobOffset = .zero
                    onAxisChanged(0)
                }
        )
    }
}
#endif

#if os(macOS)
/// Custom SKView subclass that forwards mouse/keyboard events to the scene.
private final class GameView: SKView {
    /// Ensures the view can accept key events.
    override var acceptsFirstResponder: Bool { true }

    /// Claims first-responder status when attached to a window.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    /// Forwards mouse clicks to the scene.
    override func mouseDown(with event: NSEvent) {
        scene?.mouseDown(with: event)
    }

    /// Forwards mouse drags to the scene.
    override func mouseDragged(with event: NSEvent) {
        scene?.mouseDragged(with: event)
    }

    /// Forwards key-down events to the scene.
    override func keyDown(with event: NSEvent) {
        scene?.keyDown(with: event)
    }

    /// Forwards key-up events to the scene.
    override func keyUp(with event: NSEvent) {
        scene?.keyUp(with: event)
    }
}

/// SwiftUI wrapper for the macOS SKView host.
private struct MacGameView: NSViewRepresentable {
    /// The SpriteKit scene to present.
    let scene: TubeScene

    /// Creates the SKView and presents the scene.
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

    /// Keeps the presented scene in sync with SwiftUI updates.
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
