//
//  Item.swift
//  Parachute
//
//  Created by Ben Gresham on 01/02/2026.
//

import Foundation
import SwiftData

/// Simple SwiftData model used by the template project.
@Model
final class Item {
    /// Timestamp captured when the item is created.
    var timestamp: Date
    
    /// Initializes a new item with the provided timestamp.
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
