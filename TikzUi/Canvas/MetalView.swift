//
//  MetalView.swift
//  TikzUi
//
//  Created by Mattia Marini on 24/09/23.
//


import MetalKit
import SwiftUI

class MetalView : NSView, CALayerDelegate{
    
    
    internal var tool : Binding<String>?
    
    var device : MTLDevice!
    var queue : MTLCommandQueue!
    var pipelineState : MTLRenderPipelineState!
    var rectsPipelineState : MTLRenderPipelineState!
    var computeSelectionPipelineState : MTLComputePipelineState!
    var computePipelineState : MTLComputePipelineState!
    
    
    var metalLayer : CAMetalLayer!
    var selectionLayer : SelectionLayer!
    
    internal let initialSpacing : Float = 10.0
    internal var zoomLevel :Float = 1.0
    
    internal var spacing : Float = 10.0
    internal var xoffset : Float = 0
    internal var yoffset : Float = 0
    internal var width : Float = 0
    internal var height : Float = 0
    
    
    internal var shapes : CanvasShapes = CanvasShapes()
    
    
    internal var currKey : String? = nil
    internal var currLiveAction : LiveCanvasActions = .none
    
    internal var selectionStart: NSPoint? = nil
    
    internal var currTool: Tools = .selection
    
    
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
        override_scrollWheel(with: event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        override_mouseMoved(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        override_mouseDragged(with: event)
    }
    
    
    override func mouseDown(with event: NSEvent) {
        override_mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        override_mouseUp(with: event)
    }
    
    
    
    override func keyDown(with event: NSEvent) {
        override_keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        override_keyUp(with: event)
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
    
    
    
    internal func canvasCordsFromView(_ cords: NSPoint) -> NSPoint{
        return NSPoint(x: CGFloat(( Float(cords.x) - xoffset ) / zoomLevel) , y: CGFloat(( Float(cords.y) - yoffset ) / zoomLevel))
    }
    
    
    //SETUP VIEW
    
    override func makeBackingLayer() -> CALayer {
        return override_makeBackingLayer()
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
