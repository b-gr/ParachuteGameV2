import SpriteKit
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

extension TubeScene {
    #if os(macOS)
    /// Handles mouse clicks for starting and pointer-based input.
    public override func mouseDown(with event: NSEvent) {
        lastInputEvent = "mouseDown"
        if runState == .showingScores {
            resetRun()
            return
        }
        if runState == .ready {
            startRun()
            return
        }
        if runState != .playing { return }
        inputMode = .pointer
        targetX = convertPoint(fromView: event.locationInWindow).x
    }

    /// Handles mouse drags for pointer-based steering.
    public override func mouseDragged(with event: NSEvent) {
        lastInputEvent = "mouseDragged"
        if runState != .playing { return }
        inputMode = .pointer
        targetX = convertPoint(fromView: event.locationInWindow).x
    }

    /// Handles key presses for name entry and keyboard controls.
    public override func keyDown(with event: NSEvent) {
        lastInputEvent = "keyDown:\(event.keyCode)"
        if runState == .enteringName {
            handleNameEntryKeyDown(event)
            return
        }

        if runState == .showingScores {
            if event.keyCode == 36 { // return
                resetRun()
            }
            return
        }

        if runState == .ready {
            if event.keyCode == 49 { // space
                startRun()
            }
            return
        }

        inputMode = .keyboard
        switch event.keyCode {
        case 123:
            leftKeyDown = true
        case 124:
            rightKeyDown = true
        default:
            break
        }
    }

    /// Handles key release events for keyboard controls.
    public override func keyUp(with event: NSEvent) {
        lastInputEvent = "keyUp:\(event.keyCode)"
        if runState != .playing { return }
        switch event.keyCode {
        case 123:
            leftKeyDown = false
        case 124:
            rightKeyDown = false
        default:
            break
        }
    }
    #else
    /// Placeholder for touch input start (handled via SwiftUI overlay).
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastInputEvent = "touchesBegan"
    }

    /// Placeholder for touch input updates (handled via SwiftUI overlay).
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastInputEvent = "touchesMoved"
    }
    #endif
}
