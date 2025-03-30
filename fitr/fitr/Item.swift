//
//  Item.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
