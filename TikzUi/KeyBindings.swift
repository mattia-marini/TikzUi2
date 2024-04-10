//
//  KeyBindings.swift
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

import SwiftUI

class CanvasModifiers {
    public static let selection : String? = nil
    public static let addToSelection = NSEvent.ModifierFlags.command
    public static let moveView = " "
}

class CanvasActions {
    public static let placeNode = " "
    public static let moveView = " "
}

enum LiveCanvasActions {
    case selection
    case addToSelection
    case shapeDrag
    case moveView
    case none
}
