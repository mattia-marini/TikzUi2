//
//  Computing.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView{
    
    internal func computeHighlightedShapes(_ selection: NSRect){
        let commandBuffer = queue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(computeSelectionPipelineState)
        
        let rectsBuffer = device.makeBuffer(bytes: shapes.rects, length: MemoryLayout<SimdRect>.stride * shapes.rects.count)
        var canvasInfos = CanvasInfos(xoffset: xoffset, yoffset: yoffset, width: Float(bounds.width), height: Float(bounds.height), scale: zoomLevel)
        var selectionSimd = SIMD4<Float>(Float(selection.minX), Float(selection.minY), Float(selection.maxX), Float(selection.maxY))
        
        //let rectsSelectionBuffer = device.makeBuffer(bytes: rectsSelection, length: rectsSelection.count)
        let rectsLiveSelectionBuffer = device.makeBuffer(bytes: shapes.rectsLiveSelection, length: shapes.rectsLiveSelection.count)
        let needsDisplayBuffer = device.makeBuffer(length: MemoryLayout<Bool>.size)
        
        
        commandEncoder?.setBuffer(rectsBuffer, offset: 0, index: 0)
        commandEncoder?.setBytes(&canvasInfos, length: MemoryLayout<CanvasInfos>.size, index: 1)
        commandEncoder?.setBytes(&selectionSimd, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
        commandEncoder?.setBuffer(rectsLiveSelectionBuffer, offset: 0, index: 3)
        commandEncoder?.setBuffer(needsDisplayBuffer, offset: 0, index: 4)
        //commandEncoder?.setBytes(&retainOldSelection, length: MemoryLayout<Bool>.size, index: 4)
        
        let threadPerGrid = MTLSize(width: shapes.rects.count, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder?.dispatchThreads(threadPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        
        commandBuffer?.waitUntilCompleted()
        
        let resultRects = rectsBuffer?.contents().bindMemory(to: SimdRect.self, capacity: shapes.rects.count)
        let resultRectsLiveSelection = rectsLiveSelectionBuffer?.contents().bindMemory(to: Bool.self, capacity: shapes.rects.count)
        let needsRedrawUnsafe = needsDisplayBuffer?.contents().bindMemory(to: Bool.self, capacity: 1)
        
        //rects = Array((rectsBuffer!).contents().load(as: [SimdRect].self))
        shapes.rects = Array(UnsafeBufferPointer(start: resultRects!, count: shapes.rects.count))
        shapes.rectsLiveSelection = Array(UnsafeBufferPointer(start: resultRectsLiveSelection!, count: shapes.rectsLiveSelection.count))
        let needsRedraw = (Array(UnsafeBufferPointer(start: needsRedrawUnsafe!, count: 1)))[0]
        
        
        if(needsRedraw){ metalLayer.setNeedsDisplay() }
    }
    
    internal func getTargetsUnderMouse(_ mousePos : NSPoint){
        let commandBuffer = queue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(computePipelineState)
        
        
        let rectsBuffer = device.makeBuffer(bytes: shapes.rects, length: MemoryLayout<SimdRect>.stride * shapes.rects.count)
        //var normalizedCords = float2(x: Float(mousePos.x / bounds.width) * 2 - 1, y: Float(mousePos.y / bounds.height) * 2 - 1)
        //let mouseCordsBuffer = device.makeBuffer(bytes: &normalizedCords, length: MemoryLayout<float2>.size)
        var mouseCords = SIMD2<Float>(x: Float(mousePos.x), y: Float(mousePos.y))
        let mouseCordsBuffer = device.makeBuffer(bytes: &mouseCords, length: MemoryLayout<SIMD2<Float>>.size)
        let resultBuffer = device.makeBuffer(length: MemoryLayout<Int>.size)
        
        let debugBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * 10)
        
        commandEncoder?.setBuffer(rectsBuffer, offset: 0, index: 0)
        commandEncoder?.setBuffer(mouseCordsBuffer, offset: 0, index: 1)
        commandEncoder?.setBuffer(resultBuffer, offset: 0, index: 2)
        commandEncoder?.setBytes(&xoffset, length: MemoryLayout<Float>.size, index: 3)
        commandEncoder?.setBytes(&yoffset, length: MemoryLayout<Float>.size, index: 4)
        commandEncoder?.setBytes(&zoomLevel, length: MemoryLayout<Float>.size, index: 5)
        
        commandEncoder?.setBuffer(debugBuffer,offset: 0, index: 6)
        
        let threadPerGrid = MTLSize(width: shapes.rects.count, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: computePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder?.dispatchThreads(threadPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        
        commandBuffer?.waitUntilCompleted()
        
        let result = resultBuffer?.contents().bindMemory(to: Int.self, capacity: 1)
        
        print(result![0])
        
        if(result![0] == 1){
            NSCursor.openHand.set()
        }
        else{
            NSCursor.arrow.set()
        }
        
        
        /*
         let debug = debugBuffer?.contents().bindMemory(to: Float.self, capacity: 10)
         for i in 0...9 {
         print(debug![i], terminator: "\t")
         }
         print("")
         */
        
    }
    
    internal func getSelectionBounds(_ selection: NSPoint){
    }
}
