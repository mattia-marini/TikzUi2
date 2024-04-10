//
//  GPUTask.swift
//  TikzUi
//
//  Created by Mattia Marini on 10/04/24.
//

import Metal

class GPUTask {
    
    /*
     private static func unsafeFromLet<T>(_ value : T) -> UnsafeRawPointer{
     return withUnsafeBytes(of: value) { rawBufferPointer in return rawBufferPointer.baseAddress }!
     }
     */
    private static func reconvertBuffer<T>(buffer: MTLBuffer, count : Int) -> [T]{
        return Array(UnsafeBufferPointer(start: buffer.contents().bindMemory(to: T.self, capacity: count), count: count))
    }
    
    
    private static let device = MTLCreateSystemDefaultDevice()
    private static var queue : MTLCommandQueue!
    
    private static var setArrayIntPS : MTLComputePipelineState!
    private static var setArrayFloatPS : MTLComputePipelineState!
    private static var setArrayBoolPS : MTLComputePipelineState!
    
    private static var mergeArrayBool : MTLComputePipelineState!
    
    private static var setUp = false
    private init(){ }
    
    public static func setup() {
        
        if setUp {return}
        guard let device = device else { print("errore di device"); return }
        guard let library = device.makeDefaultLibrary() else {print("errore makePipeline"); return}
        
        do {
            setArrayIntPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_int")!)
            setArrayFloatPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_float")!)
            setArrayBoolPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_bool")!)
            mergeArrayBool = try device.makeComputePipelineState(function: library.makeFunction(name: "merge_array_bool")!)
        }
        catch let error as NSError{
            print("Errore nella creazione della pipeline")
            print(error)
        }
        
        queue = device.makeCommandQueue()
        setUp = true
    }
    
    
    
    
    public static func setArray(_ v : inout [Bool], value : Bool){
        setArrayHelper(&v, value: value)
    }
    
    public static func setArray(_ v : inout [Int64], value : Int64){
        setArrayHelper(&v, value: value)
    }
    
    public static func setArray(_ v : inout [Float], value : Float){
        setArrayHelper(&v, value: value)
    }
    
    private static func setArrayHelper<T>(_ v : inout [T], value: T){
        
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
        print("cpu func")
        for i in 0...v.count - 1{
            v[i] = value
        }
    }
    
    
    
    
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
        commandEncoder?.setComputePipelineState(mergeArrayBool)
        
        
        let array1Buffer = device?.makeBuffer(bytes: v1, length: MemoryLayout<Bool>.stride * v1.count)
        let array2Buffer = device?.makeBuffer(bytes: &v2, length: MemoryLayout<Bool>.stride * v2.count)
        
        commandEncoder?.setBuffer(array1Buffer, offset: 0, index: 0 )
        commandEncoder?.setBuffer(array2Buffer, offset: 0, index: 1 )
        commandEncoder?.dispatchThreads(MTLSize(width: v2.count, height: 1, depth: 1), threadsPerThreadgroup:MTLSize(width: GPUTask.mergeArrayBool.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
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
