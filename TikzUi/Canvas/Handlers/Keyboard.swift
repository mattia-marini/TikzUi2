//
//  Keyboard.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView {
    
    func override_keyDown(with event: NSEvent) {
        if(currLiveAction == .none ){
            
            //globals to change tool
            if (event.characters == CanvasModifiers.globals.placeNodeTool){
                currTool = .placeNode
                tool?.wrappedValue = "PlaceNode"
            }
            else if (event.characters == CanvasModifiers.globals.selectionTool){
                currTool = .selection
                tool?.wrappedValue = "Selection"
            }
            
            else if (event.characters == CanvasModifiers.selection.moveView){
                NSCursor.closedHand.set()
                currLiveAction = .moveView
                tool?.wrappedValue = "PlaceNode"
            }
        }
        
        
        currKey = event.characters
    }
    
    func override_keyUp(with event: NSEvent) {
        if (currLiveAction == .moveView){
            currLiveAction = .none
            NSCursor.arrow.set()
        }
        
        currKey = nil
    }
}
