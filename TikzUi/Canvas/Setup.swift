//
//  Setup.swift
//  TikzUi
//
//  Created by Mattia Marini on 18/04/24.
//

import AppKit

extension MetalView {
    
    internal func makePipeline() {
        
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
    
    
    func override_makeBackingLayer() -> CALayer {
        
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
