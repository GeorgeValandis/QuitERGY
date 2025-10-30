//
//  StreakRecord.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import SwiftData

@Model
final class StreakRecord {
    var date: Date
    var drinksLogged: Int

    init(date: Date, drinksLogged: Int) {
        self.date = date
        self.drinksLogged = drinksLogged
    }
}
