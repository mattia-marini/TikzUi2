//
//  MouseSingle.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView {
    
    
    func override_mouseDown(with event: NSEvent) {
        
        
        if(currTool == Tools.selection){
            if(currLiveAction == .none && currKey == CanvasModifiers.selection.selection){
                if event.modifierFlags.contains(CanvasModifiers.selection.addToSelection) {
                    //print("addtoselection")
                    currLiveAction = .addToSelection
                }
                else{
                    GPUTask.setArray(&shapes.rectsSelection, value: false)
                    currLiveAction = .selection
                    metalLayer.setNeedsDisplay()
                }
                selectionStart = convert(event.locationInWindow, from: nil)
                //print(event.modifierFlags.contains(CanvasModifiers.addToSelection))
                //print(CanvasModifiers.addToSelection)
            }
            
        }
        
    }
    
    func override_mouseUp(with event: NSEvent) {
        
        /*
         if currLiveAction == LiveCanvasActions.selection || currLiveAction == LiveCanvasActions.addToSelection{
         GPUTask.mergeArrays(shapes.rectsLiveSelection, into: &shapes.rectsSelection)
         GPUTask.setArray(&shapes.rectsLiveSelection, value: false)
         }
         */
        
        if currTool == .selection {
            GPUTask.mergeArrays(shapes.rectsLiveSelection, into: &shapes.rectsSelection)
            GPUTask.setArray(&shapes.rectsLiveSelection, value: false)
            selectionStart = nil
            selectionLayer.selection = nil
            selectionLayer.setNeedsDisplay()
        }
        
        else if currTool == .placeNode {
            let viewCords = convert(event.locationInWindow, from: nil)
            shapes.addNode(canvasCordsFromView(viewCords))
            metalLayer.setNeedsDisplay()
        }
        
        currLiveAction = .none
    }
}
