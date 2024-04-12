//
//  KeyBindings.swift
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

import SwiftUI

class CanvasModifiers {
    public static let selection = SelectionCanvasModifiers()
    public static let drawLines = DrawLineCanvasModifiers()
    public static let placeNodes = PlaceNodeCanvasModifiers()
    public static let globals = GlobalCanvasModifiers()
}

class SelectionCanvasModifiers {
    public let selection : String? = nil
    public let addToSelection = NSEvent.ModifierFlags.command
    public let moveView = " "
}

class DrawLineCanvasModifiers {
}

class PlaceNodeCanvasModifiers {
}

class GlobalCanvasModifiers {
    public let placeNodeTool = "n"
    public let selectionTool = "s"
    public let drawLineTool = "d"
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

