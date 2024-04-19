//
//  Drawing.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView {
    
    internal func drawGrid(_ drawable : CAMetalDrawable){
        
        
        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
        
        guard   let commandBuffer = queue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else{
            print("errore di rendering")
            return
        }
        
        let modXOffset = xoffset.truncatingRemainder(dividingBy: spacing)
        let modYOffset = yoffset.truncatingRemainder(dividingBy: spacing)
        
        let infos = [width, height, modXOffset, modYOffset, spacing]
        
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBytes(infos, length: MemoryLayout<Float>.size * infos.count, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: Int( (floor((infos[0] - modXOffset) / spacing)+1) * (floor((infos[1] - modYOffset) / spacing)+1)))
        
        
        renderEncoder.endEncoding()
        
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        
    }
    
    internal func drawRects(_ drawable: CAMetalDrawable){
        
        
        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .load
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
        
        
        guard   let commandBuffer = queue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else{
            print("errore di rendering")
            return
        }
        
        let buffer = metalLayer.device?.makeBuffer(bytes: shapes.rects, length: MemoryLayout<SimdRect>.stride * shapes.rects.count, options: [])
        
        let rectsSelectionBuffer = device.makeBuffer(bytes: shapes.rectsSelection, length: shapes.rectsSelection.count)
        let rectsLiveSelectionBuffer = device.makeBuffer(bytes: shapes.rectsLiveSelection, length: shapes.rectsLiveSelection.count)
        
        renderEncoder.setRenderPipelineState(rectsPipelineState)
        renderEncoder.setVertexBytes(&width, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setVertexBytes(&height, length: MemoryLayout<Float>.size, index: 1)
        renderEncoder.setVertexBytes(&zoomLevel, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&xoffset, length: MemoryLayout<Float>.size, index: 3)
        renderEncoder.setVertexBytes(&yoffset, length: MemoryLayout<Float>.size, index: 4)
        renderEncoder.setVertexBytes(&spacing, length: MemoryLayout<Float>.size, index: 5)
        //renderEncoder.setVerte
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 6 )
        renderEncoder.setVertexBuffer(rectsSelectionBuffer, offset: 0, index: 7 )
        renderEncoder.setVertexBuffer(rectsLiveSelectionBuffer, offset: 0, index: 8 )
        //renderEncoder.setVertexBytes(rects, length: MemoryLayout<SIMD4<Float>>.stride * rects.count, index: 6)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: shapes.rects.count)
        
        
        renderEncoder.endEncoding()
        
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        
        drawable.present()
    }
    
}
