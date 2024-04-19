//
//  GPUTask.swift
//  TikzUi
//
//  Created by Mattia Marini on 10/04/24.
//

import Metal

internal class GPUTask {
    
    /*
     private static func unsafeFromLet<T>(_ value : T) -> UnsafeRawPointer{
     return withUnsafeBytes(of: value) { rawBufferPointer in return rawBufferPointer.baseAddress }!
     }
     */
    
    static let device = MTLCreateSystemDefaultDevice()
    static var queue : MTLCommandQueue!
    
    static var setUp = false
    
    private init(){ }
    
    public static func setup() {
        
        if setUp {return}
        guard let device = device else { print("errore di device"); return }
        guard let library = device.makeDefaultLibrary() else {print("errore creazione libreria"); return}
        
        
        do {
            setArrayIntPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_int")!)
            setArrayFloatPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_float")!)
            setArrayBoolPS = try device.makeComputePipelineState(function: library.makeFunction(name: "set_array_bool")!)
            mergeArrayBoolPS = try device.makeComputePipelineState(function: library.makeFunction(name: "merge_array_bool")!)
        }
        catch let error as NSError{
            print("Errore nella creazione della pipeline")
            print(error)
        }
        
        queue = device.makeCommandQueue()
        setUp = true
    }
    
}
