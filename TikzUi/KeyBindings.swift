//
//  KeyBindings.swift
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

import Foundation

class CanvasModifiers {
    public static let selection : String? = nil
    public static let moveView = " "
}

class CanvasActions {
    public static let placeNode = " "
    public static let moveView = " "
}

enum LiveCanvasActions {
    case selection
    case shapeDrag
    case moveView
    case none
}
