//
//  MetalView.swift
//  TikzUi
//
//  Created by Mattia Marini on 24/09/23.
//


import MetalKit
import SwiftUI

class MetalView : NSView, CALayerDelegate{
    
    var device : MTLDevice!
    var queue : MTLCommandQueue!
    var pipelineState : MTLRenderPipelineState!
    var rectsPipelineState : MTLRenderPipelineState!
    var computePipelineState : MTLComputePipelineState!
    
    
    var metalLayer : CAMetalLayer!
    var sublayer : CAMetalLayer!
    
    private let initialSpacing : Float = 10.0
    private var zoomLevel :Float = 1.0
    
    private var spacing : Float = 10.0
    private var xoffset : Float = 0
    private var yoffset : Float = 0
    private var width : Float = 0
    private var height : Float = 0
    
    private var rects : [SIMD4<Float>] = [.init(0, 0, 300, 100)]
    
    var trackingArea: NSTrackingArea?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        width = Float(bounds.width)
        height = Float(bounds.height)
        generateRects()
        updateTrackingAreas()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        width = Float(bounds.width)
        height = Float(bounds.height)
        generateRects()
        updateTrackingAreas()
    }
    
    override func mouseDragged(with event: NSEvent) {
        xoffset += Float(event.deltaX)
        yoffset -= Float(event.deltaY)
        setNeedsDisplay(bounds)
        //print(event.deltaX)
        print(xoffset)
    }
    
    override func scrollWheel(with event: NSEvent) {
        
        
        //let oldSpacing = spacing
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
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        //print("moved")
        let windowCords = convert(event.locationInWindow, from: nil)
        computeSnaps(windowCords)
    }
    
    
    override func keyUp(with event: NSEvent) {
    }
    
    override func keyDown(with event: NSEvent) {
        //let locationInView = convert(event.locationInWindow, from: nil)
        //computeSnaps(locationInView)
        //print(locationInView)
    }
    
    func display(_ layer: CALayer) {
        
        let drawable = metalLayer.nextDrawable()!
        drawGrid(drawable)
        drawRects(drawable)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        width = Float(newSize.width)
        height = Float(newSize.height)
        // the conversion below is necessary for high DPI drawing
        metalLayer.drawableSize = convertToBacking(newSize)
        self.viewDidChangeBackingProperties()
    }
    
    override func viewDidChangeBackingProperties() {
        guard let window = self.window else { return }
        // This is necessary to render correctly on retina displays with the topLeft placement policy
        metalLayer.contentsScale = window.backingScaleFactor
    }
    
    /*
     private func drawLines(){
     let drawable = sublayer.nextDrawable()!
     
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
     
     drawable.present()
     }
     */
    
    private func generateRects(){
        let xstep: Float = 17.0, ystep: Float = 17.0
        let width: Float = 15.0, height: Float = 15.0
        var x: Float = 0.0
        
        while (x < 100){
            
            var y: Float = 0.0
            while (y < 10000){
                self.rects.append(SIMD4<Float>(x,y,x+width,y + height))
                y += ystep
            }
            x += xstep
        }
        
    }
    
    private func drawGrid(_ drawable : CAMetalDrawable){
        
        
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
    
    private func drawRects(_ drawable: CAMetalDrawable){
        
        
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
        
        
        renderEncoder.setRenderPipelineState(rectsPipelineState)
        renderEncoder.setVertexBytes(&width, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setVertexBytes(&height, length: MemoryLayout<Float>.size, index: 1)
        renderEncoder.setVertexBytes(&zoomLevel, length: MemoryLayout<Float>.size, index: 2)
        renderEncoder.setVertexBytes(&xoffset, length: MemoryLayout<Float>.size, index: 3)
        renderEncoder.setVertexBytes(&yoffset, length: MemoryLayout<Float>.size, index: 4)
        renderEncoder.setVertexBytes(&spacing, length: MemoryLayout<Float>.size, index: 5)
        //renderEncoder.setVerte
        let buffer = metalLayer.device?.makeBuffer(bytes: rects, length: MemoryLayout<SIMD4<Float>>.stride * rects.count, options: [])
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 6 )
        //renderEncoder.setVertexBytes(rects, length: MemoryLayout<SIMD4<Float>>.stride * rects.count, index: 6)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: rects.count)
        
        
        renderEncoder.endEncoding()
        
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        
        drawable.present()
    }
    
    private func computeSnaps(_ mousePos : NSPoint){
        let commandBuffer = queue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(computePipelineState)
        
        
        let rectsBuffer = device.makeBuffer(bytes: rects, length: MemoryLayout<SIMD4<Float>>.stride * rects.count)
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
        
        let threadPerGrid = MTLSize(width: rects.count, height: 1, depth: 1)
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
    
    private func makePipeline() {
        
        guard let library = metalLayer.device?.makeDefaultLibrary() else {print("errore makePipeline"); return}
        
        //Grid pipeline
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = library.makeFunction(name: "vertex_function")
        pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "fragment_function")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        
        //Rects pipeline
        let rectsPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        rectsPipelineStateDescriptor.vertexFunction = library.makeFunction(name: "rects_vertex_function")
        rectsPipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "rects_fragment_function")
        
        let colorAttachment = rectsPipelineStateDescriptor.colorAttachments[0]!
        colorAttachment.pixelFormat = .bgra8Unorm
        
        //server per far funzionare l'alpha
        colorAttachment.isBlendingEnabled = true
        
        colorAttachment.sourceRGBBlendFactor = .sourceAlpha
        colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        
        //Compute pipeline
        //let computePipelineStateDescriptor = MTLComputePipelineDescriptor()
        //computePipelineStateDescriptor.computeFunction = library.makeFunction(name: "computeFunction")
        
        
        
        do {
            pipelineState = try metalLayer.device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            rectsPipelineState = try metalLayer.device?.makeRenderPipelineState(descriptor: rectsPipelineStateDescriptor)
            computePipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "computeFunction")!)
        }
        catch let error as NSError{
            print("Errore nella creazione della pipeline")
            print(error)
        }
        
    }
    
    override func makeBackingLayer() -> CALayer {
        
        self.device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()
        sublayer = CAMetalLayer()
        metalLayer.addSublayer(sublayer)
        
        metalLayer.delegate = self
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.device = device
        
        queue = metalLayer.device?.makeCommandQueue()
        
        metalLayer.allowsNextDrawableTimeout = false
        
        // these properties are crucial to resizing working
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
        
        makePipeline()
        
        return metalLayer
    }
    
}


struct Renderer : NSViewRepresentable {
    
    func makeNSView(context: Context) -> some NSView {
        return MetalView(frame: .zero)
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
}
