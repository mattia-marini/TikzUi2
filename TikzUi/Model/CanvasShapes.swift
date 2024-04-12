//
//  CanvasShapes.swift
//  TikzUi
//
//  Created by Mattia Marini on 11/04/24.
//

import Foundation


class CanvasShapes {
    var rects : [SimdRect] = []
    var rectsSelection : [Bool] = []
    var rectsLiveSelection : [Bool] = []
    
    private var nodeWidth : Float = 10.0
    private var nodeHeight : Float = 10.0
    
    private func addRect(_ rect : NSRect){
        rects.append(SimdRect(bounds: SIMD4<Float>(x: Float(rect.minX), y: Float(rect.minY), z: Float(rect.maxX), w: Float(rect.maxY))))
        rectsSelection.append(false)
        rectsLiveSelection.append(false)
    }
    
    func addNode(_ pos : NSPoint){
        let rect = NSRect(x: pos.x - CGFloat(nodeWidth / 2), y: pos.y - CGFloat(nodeHeight / 2),
                      width: CGFloat(nodeWidth), height: CGFloat(nodeHeight))
        addRect(rect)
    }
    
    func generateRects(){
        let xstep: Float = 17.0, ystep: Float = 17.0
        var x: Float = 0.0
        
        let xAmmount = 10_000 as Float
        let yAmmount = 10_000 as Float
        
        while (x < xAmmount){
            
            var y: Float = 0.0
            while (y < yAmmount){
                addNode(.init(x: CGFloat(x), y: CGFloat(y) ))
                y += ystep
            }
            x += xstep
        }
        
        
    }
    
}
