import SpriteKit

extension TubeScene {
    /// Linearly interpolates between two values with clamped t.
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }

    /// Checks whether two physics bodies match a given category pair.
    func isPair(_ a: SKPhysicsBody, _ b: SKPhysicsBody, _ ca: UInt32, _ cb: UInt32) -> Bool {
        (a.categoryBitMask == ca && b.categoryBitMask == cb) || (a.categoryBitMask == cb && b.categoryBitMask == ca)
    }

    /// Converts a pickup kind into a stable string key.
    func kindKey(_ kind: PickupKind) -> String {
        switch kind {
        case .shield: return "shield"
        case .boost: return "boost"
        case .slow: return "slow"
        case .coin: return "coin"
        }
    }
}
