//
//  MergeArrays.swift
//  TikzUi
//
//  Created by Mattia Marini on 19/04/24.
//

import Metal

internal extension GPUTask{
    static var mergeArrayBoolPS : MTLComputePipelineState!
    
    
    public static func mergeArrays(_ v1 : [Bool], into v2 : inout [Bool]){
        
        guard GPUTask.device != nil else {
            mergeArraysCPU(v1, into: &v2)
            return
        }
        
        if v1.count < 10_000 {
            mergeArraysCPU(v1, into: &v2)
            return
        }
        
        mergeArraysGPU(v1, into: &v2)
    }
    
    public static func mergeArraysGPU(_ v1 : [Bool], into v2 : inout [Bool]){
        let commandBuffer = queue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(mergeArrayBoolPS)
        
        
        let array1Buffer = device?.makeBuffer(bytes: v1, length: MemoryLayout<Bool>.stride * v1.count)
        let array2Buffer = device?.makeBuffer(bytes: &v2, length: MemoryLayout<Bool>.stride * v2.count)
        
        commandEncoder?.setBuffer(array1Buffer, offset: 0, index: 0 )
        commandEncoder?.setBuffer(array2Buffer, offset: 0, index: 1 )
        commandEncoder?.dispatchThreads(MTLSize(width: v2.count, height: 1, depth: 1), threadsPerThreadgroup:MTLSize(width: GPUTask.mergeArrayBoolPS.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        
        commandBuffer?.waitUntilCompleted()
        
        v2 = reconvertBuffer(buffer: array2Buffer!, count: v2.count)
    }
    
    private static func mergeArraysCPU(_ v1 : [Bool], into v2 : inout [Bool]){
        for i in 0...v2.count - 1 {
            v2[i] = v2[i] || v1[i]
        }
    }
}
