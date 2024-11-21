//
//  Item.swift
//  nodetool
//
//  Created by Maximus Chow on 21/11/24.
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
