//
//  MetalView.swift
//  TikzUi
//
//  Created by Mattia Marini on 24/09/23.
//


import MetalKit
import SwiftUI

class MetalView : NSView, CALayerDelegate{
    
    
    private var tool : Binding<String>?
    
    var device : MTLDevice!
    var queue : MTLCommandQueue!
    var pipelineState : MTLRenderPipelineState!
    var rectsPipelineState : MTLRenderPipelineState!
    var computeSelectionPipelineState : MTLComputePipelineState!
    var computePipelineState : MTLComputePipelineState!
    
    
    var metalLayer : CAMetalLayer!
    var selectionLayer : SelectionLayer!
    
    private let initialSpacing : Float = 10.0
    private var zoomLevel :Float = 1.0
    
    private var spacing : Float = 10.0
    private var xoffset : Float = 0
    private var yoffset : Float = 0
    private var width : Float = 0
    private var height : Float = 0
    
    
    private var shapes : CanvasShapes = CanvasShapes()
    
    
    private var currKey : String? = nil
    private var currLiveAction : LiveCanvasActions = .none
    
    private var selectionStart: NSPoint? = nil
    
    private var currTool: Tools = .selection
    
    
    var trackingArea: NSTrackingArea?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    convenience init(frame frameRect: NSRect, tool: Binding<String>)  {
        self.init(frame: frameRect)
        self.tool = tool
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        width = Float(bounds.width)
        height = Float(bounds.height)
        shapes.generateRects()
        updateTrackingAreas()
        GPUTask.setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        width = Float(bounds.width)
        height = Float(bounds.height)
        shapes.generateRects()
        updateTrackingAreas()
        GPUTask.setup()
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
    
    
    override func scrollWheel(with event: NSEvent) {
        
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
    
    override func mouseMoved(with event: NSEvent) {
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        
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
    
    override func mouseDown(with event: NSEvent) {
        
        
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
    
    override func mouseUp(with event: NSEvent) {
        
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
    
    override func keyDown(with event: NSEvent) {
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
    
    override func keyUp(with event: NSEvent) {
        if (currLiveAction == .moveView){
            currLiveAction = .none
            NSCursor.arrow.set()
        }
        
        currKey = nil
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
         
         metalLayer.contentsScale = window.backingScaleFactor
         selectionLayer.contentsScale = window.backingScaleFactor
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
    
    private func computeHighlightedShapes(_ selection: NSRect){
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
    
    private func getTargetsUnderMouse(_ mousePos : NSPoint){
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
   
    private func canvasCordsFromView(_ cords: NSPoint) -> NSPoint{
        return NSPoint(x: CGFloat(( Float(cords.x) - xoffset ) / zoomLevel) , y: CGFloat(( Float(cords.y) - yoffset ) / zoomLevel))
    }
    
    private func getSelectionBounds(_ selection: NSPoint){
        
    }
    
    //SETUP VIEW
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
            computeSelectionPipelineState = try device.makeComputePipelineState(function: library.makeFunction(name: "compute_selection")!)
        }
        catch let error as NSError{
            print("Errore nella creazione della pipeline")
            print(error)
        }
        
    }
    
    override func makeBackingLayer() -> CALayer {
        
        self.device = MTLCreateSystemDefaultDevice()
        self.queue = device?.makeCommandQueue()
        
        metalLayer = CAMetalLayer()
        
        metalLayer.delegate = self
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.device = device
        
        metalLayer.allowsNextDrawableTimeout = false
        
        // these properties are crucial to resizing working
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
        
        
        selectionLayer = SelectionLayer()
        selectionLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        selectionLayer.needsDisplayOnBoundsChange = true
        
        makePipeline()
        
        let wrapperLayer = CALayer()
        wrapperLayer.addSublayer(metalLayer)
        wrapperLayer.addSublayer(selectionLayer)
        
        return wrapperLayer
    }
    
}
















struct Renderer : NSViewRepresentable {
    
    @Binding var tool: String
    
    func makeNSView(context: Context) -> some NSView {
        return MetalView(frame: .zero, tool: $tool)
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        
    }
    
}


class sublayerDelegate: NSObject, CALayerDelegate{
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        ctx.addPath(.init(ellipseIn: .init(x: 0, y: 0, width: 100, height: 300), transform: nil))
        ctx.fillPath()
        print("prova draw")
    }
    
    
    func display(_ layer: CALayer) {
        //layer.dra
        print("sublayer")
    }
}


class SelectionLayer : CALayer {
    var selection: CGRect?
    
    override func draw(in ctx: CGContext) {
        guard let selection = selection else {return}
        
        
        if hasDarkMode() {
            ctx.setFillColor(gray: 1, alpha: 0.5)
            ctx.setStrokeColor(NSColor.white.cgColor)
        }
        else {
            ctx.setFillColor(gray: 0.5, alpha: 0.5)
            ctx.setStrokeColor(NSColor.systemGray.cgColor)
        }
        ctx.fill(selection)
        ctx.stroke(selection)
    }
    
    override func action(forKey event: String) -> CAAction? {
        nil
    }
    
}
