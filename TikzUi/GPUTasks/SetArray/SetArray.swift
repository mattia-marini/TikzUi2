//
//  SetArray.swift
//  TikzUi
//
//  Created by Mattia Marini on 19/04/24.
//

import Metal

internal extension GPUTask {
    
    static var setArrayIntPS : MTLComputePipelineState!
    static var setArrayFloatPS : MTLComputePipelineState!
    static var setArrayBoolPS : MTLComputePipelineState!
    
    public static func setArray(_ v : inout [Bool], value : Bool){
        setArrayDispatch(&v, value: value)
    }
    
    public static func setArray(_ v : inout [Int64], value : Int64){
        setArrayDispatch(&v, value: value)
    }
    
    public static func setArray(_ v : inout [Float], value : Float){
        setArrayDispatch(&v, value: value)
    }
    
    private static func setArrayDispatch<T>(_ v : inout [T], value: T) {
        
        guard let device = GPUTask.device else {
            setArrayCPU(&v, value: value)
            return
        }
        
        if v.count < 10_000 {
            setArrayCPU(&v, value: value)
            return
        }
        
        print("metal func")
        
        let commandBuffer = GPUTask.queue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        var maxThreadPerGroup : Int
        if T.self == Int64.self {
            maxThreadPerGroup = setArrayIntPS.maxTotalThreadsPerThreadgroup
            commandEncoder?.setComputePipelineState(setArrayIntPS)
        } else if T.self == Float.self {
            maxThreadPerGroup = setArrayFloatPS.maxTotalThreadsPerThreadgroup
            commandEncoder?.setComputePipelineState(setArrayFloatPS)
        } else if T.self == Bool.self {
            maxThreadPerGroup = setArrayBoolPS.maxTotalThreadsPerThreadgroup
            commandEncoder?.setComputePipelineState(setArrayBoolPS)
        } else {
            print("tipo non supportato")
            return
        }
       
        
        let buffer = device.makeBuffer(bytes: v, length: MemoryLayout<T>.stride * v.count)
        
        commandEncoder?.setBuffer(buffer, offset: 0, index: 0)
        commandEncoder?.setBytes(withUnsafeBytes(of: value) { rawBufferPointer in return rawBufferPointer.baseAddress }!, length: MemoryLayout<T>.stride, index: 1)
        
        
        commandEncoder?.dispatchThreads(MTLSize(width: v.count, height: 1, depth: 1), threadsPerThreadgroup:MTLSize(width: maxThreadPerGroup, height: 1, depth: 1))
        
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        
        commandBuffer?.waitUntilCompleted()
        
        let contents = buffer?.contents().bindMemory(to: T.self, capacity: v.count)
        v = Array(UnsafeBufferPointer(start: contents, count: v.count))
        
    }
    
    private static func setArrayCPU <T>( _ v: inout [T], value: T ){
        for i in 0...v.count - 1{
            v[i] = value
        }
    }
    
}
