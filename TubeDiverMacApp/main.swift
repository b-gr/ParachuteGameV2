import Cocoa
import SpriteKit
import TubeDiverCore

/// SKView subclass that forwards input events to the scene.
final class GameView: SKView {
    /// Allows the view to receive keyboard focus.
    override var acceptsFirstResponder: Bool { true }

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

/// AppKit delegate that creates and configures the game window.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Main application window reference.
    private var window: NSWindow?

    /// Configures the main window and presents the SpriteKit scene.
    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let gameplaySize = NSSize(width: 390, height: 844)
        let initialScale: CGFloat = 1.0
        let size = NSSize(width: gameplaySize.width * initialScale, height: gameplaySize.height * initialScale)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TubeDiver"
        window.center()
        window.contentAspectRatio = gameplaySize

        let skView = GameView(frame: NSRect(origin: .zero, size: size))
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        skView.showsFPS = true
        skView.showsNodeCount = true

        window.contentView = skView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(skView)

        let scene = TubeScene(size: gameplaySize)
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)

        app.activate(ignoringOtherApps: true)
        self.window = window
    }

    /// Exits when the last window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

/// Manual application startup for the AppKit target.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
