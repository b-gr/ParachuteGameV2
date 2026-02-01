import Foundation
import SpriteKit
#if canImport(AppKit)
import AppKit
#endif

extension TubeScene {
    /// Indicates whether the scene is currently collecting a name.
    public var isEnteringName: Bool {
        runState == .enteringName
    }

    /// Indicates whether the run is in the ready state.
    public var isReady: Bool {
        runState == .ready
    }

    /// Indicates whether the high-score list is being shown.
    public var isShowingScores: Bool {
        runState == .showingScores
    }

    /// Indicates whether gameplay is active.
    public var isPlaying: Bool {
        runState == .playing
    }

    /// Returns the current name-entry buffer.
    public func currentNameBuffer() -> String {
        nameBuffer
    }

    /// Updates the name buffer with allowed characters only.
    public func updateNameBuffer(_ raw: String) {
        guard runState == .enteringName else { return }
        let filtered = raw.unicodeScalars.compactMap { scalar -> Character? in
            if scalar.value == 0x1B { return nil }
            let c = Character(scalar)
            if c.isLetter || c.isNumber || c == " " || c == "-" || c == "_" {
                return c
            }
            return nil
        }
        nameBuffer = String(filtered.prefix(14))
        refreshNamePrompt()
    }

    /// Submits the current name entry, if applicable.
    public func submitNameEntry() {
        guard runState == .enteringName else { return }
        saveCurrentScore()
    }

    /// Spawns milestone banners based on elapsed time.
    func updateMilestones() {
        let s = Int(elapsed)
        while s >= nextMilestoneSeconds {
            spawnMilestonePlane(seconds: nextMilestoneSeconds)
            nextMilestoneSeconds = nextMilestone(after: nextMilestoneSeconds)
        }
    }

    /// Computes the next milestone threshold after the given value.
    func nextMilestone(after value: Int) -> Int {
        switch value {
        case 10: return 20
        case 20: return 30
        case 30: return 60
        case 60: return 120
        default:
            if value < 120 { return 120 }
            return value + 60
        }
    }

    /// Transitions into the name-entry flow after a run ends.
    func presentNameEntry() {
        runState = .enteringName
        world.isPaused = true

        let seconds = Int(elapsed)
        let multiplier = 1 + coinsThisRun
        let score = seconds * multiplier

        scorePanel.isHidden = false
        hudBar.run(.fadeAlpha(to: 0.0, duration: 0.25))
        scoreLabel.run(.fadeAlpha(to: 0.0, duration: 0.25))
        statusLabel.numberOfLines = 0
        statusLabel.text = "Game Over\nTime: \(seconds)s  Coins: \(coinsThisRun)  \nScore: \(score)\n\nEnter your name and press Return:\n\(nameBuffer.isEmpty ? "_" : nameBuffer)"
    }

    #if os(macOS)
    /// Handles key presses while entering a name on macOS.
    func handleNameEntryKeyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 51:
            if !nameBuffer.isEmpty {
                nameBuffer.removeLast()
            }
            refreshNamePrompt()
        case 36:
            saveCurrentScore()
        default:
            guard let chars = event.characters, !chars.isEmpty else { return }
            for scalar in chars.unicodeScalars {
                if scalar.value == 0x1B { continue }
                let c = Character(scalar)
                if c.isLetter || c.isNumber || c == " " || c == "-" || c == "_" {
                    if nameBuffer.count < 14 {
                        nameBuffer.append(c)
                    }
                }
            }
            refreshNamePrompt()
        }
    }
    #endif

    /// Refreshes the on-screen prompt while entering a name.
    func refreshNamePrompt() {
        guard runState == .enteringName else { return }
        let seconds = Int(elapsed)
        let multiplier = 1 + coinsThisRun
        let score = seconds * multiplier
        scorePanel.isHidden = false
        statusLabel.numberOfLines = 0
        statusLabel.text = "Game Over\nTime: \(seconds)s  Coins: \(coinsThisRun)  \nScore: \(score)\n\nEnter your name and press Return:\n\(nameBuffer.isEmpty ? "_" : nameBuffer)"
    }

    /// Builds a score entry from the current run metrics.
    func currentScoreEntry() -> ScoreEntry {
        let seconds = Int(elapsed)
        let multiplier = 1 + coinsThisRun
        let score = seconds * multiplier
        let name = nameBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Player" : nameBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        let iso = ISO8601DateFormatter()
        return ScoreEntry(
            name: name,
            score: score,
            seconds: seconds,
            coins: coinsThisRun,
            dateISO8601: iso.string(from: Date())
        )
    }

    /// Saves the current score and shows the leaderboard.
    func saveCurrentScore() {
        let entry = currentScoreEntry()
        highScores.append(entry)
        highScores.sort { $0.score > $1.score }
        if highScores.count > 10 {
            highScores = Array(highScores.prefix(10))
        }
        persistHighScores()

        runState = .showingScores
        statusLabel.numberOfLines = 0
        scorePanel.isHidden = false
        statusLabel.text = leaderboardText(current: entry)
    }

    /// Renders the leaderboard text for the HUD.
    func leaderboardText(current: ScoreEntry) -> String {
        var lines: [String] = []
        lines.append("Your score has been saved!")
        lines.append("\nHigh Scores")
        for (i, e) in highScores.enumerated() {
            lines.append("\(i + 1). \(e.name)  \(e.score)")
        }
#if os(iOS)
        lines.append("\nTap Start to restart")
#else
        lines.append("\nClick (or press Return) to restart")
#endif
        return lines.joined(separator: "\n")
    }

    /// Loads high scores from user defaults.
    func loadHighScores() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "TubeDiverHighScores") else { return }
        do {
            highScores = try JSONDecoder().decode([ScoreEntry].self, from: data)
        } catch {
            highScores = []
        }
    }

    /// Persists high scores to user defaults.
    func persistHighScores() {
        do {
            let data = try JSONEncoder().encode(highScores)
            UserDefaults.standard.set(data, forKey: "TubeDiverHighScores")
        } catch {
            // ignore for prototype
        }
    }
}
