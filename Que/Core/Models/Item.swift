//
//  Item.swift
//  Que
//
//  Created by Hasan Kılınç on 23.07.2025.
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
