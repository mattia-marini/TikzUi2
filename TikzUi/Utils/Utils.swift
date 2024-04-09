//
//  Utils.swift
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

import SwiftUI

func hasDarkMode() -> Bool {
    let apparence = NSApp.effectiveAppearance
    return apparence.name == .darkAqua
}
