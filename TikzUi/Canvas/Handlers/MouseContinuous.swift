//
//  MouseContinuous.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView {
    
    internal func override_mouseMoved(with event: NSEvent){
    }
    
    internal func override_scrollWheel(with event: NSEvent){
        let oldZoomLevel = zoomLevel
        
        zoomLevel = max(zoomLevel + Float(event.scrollingDeltaY) * 0.01, 0.1)
        
        spacing = initialSpacing * zoomLevel
        
        let viewMouseX = Float(convert(event.locationInWindow, from: nil).x)
        let viewMouseY = Float(convert(event.locationInWindow, from: nil).y)
        
        //print("\(viewMouseX) -- \(viewMouseY)")
        //let ammount = spacing/oldSpacing
        
        xoffset = viewMouseX - (viewMouseX - xoffset) * zoomLevel / oldZoomLevel
        yoffset = viewMouseY - (viewMouseY - yoffset) * zoomLevel / oldZoomLevel
        
        /*
         let predictedX = viewMouseX - (((viewMouseX - xoffset).truncatingRemainder(dividingBy:  oldSpacing))*ammount)
         self.xoffset =  predictedX.truncatingRemainder(dividingBy: spacing)
         
         let predictedY = viewMouseY - (((viewMouseY - yoffset).truncatingRemainder(dividingBy:  oldSpacing))*ammount)
         self.yoffset =  predictedY.truncatingRemainder(dividingBy: spacing)
         */
        setNeedsDisplay(bounds)
        
    }
    
    internal func override_mouseDragged(with event: NSEvent){
        
        if(currLiveAction == .moveView){
            xoffset += Float(event.deltaX)
            yoffset -= Float(event.deltaY)
            setNeedsDisplay(bounds)
        }
        
        else if (currLiveAction == .selection || currLiveAction == .addToSelection){
            let viewCords = convert(event.locationInWindow, from: nil)
            
            if selectionStart == nil { self.selectionStart = viewCords }
            guard let selectionStart = selectionStart else {return}
            
            let currSel = NSRect(origin: selectionStart, size: .init(width: viewCords.x - selectionStart.x, height: viewCords.y - selectionStart.y))
            selectionLayer.selection = currSel
            selectionLayer.setNeedsDisplay()
            
            computeHighlightedShapes(currSel)
            
        }
        
    }
    
}
