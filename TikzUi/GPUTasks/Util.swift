//
//  Util.swift
//  TikzUi
//
//  Created by Mattia Marini on 19/04/24.
//

import Metal

internal extension GPUTask{
    
    static func reconvertBuffer<T>(buffer: MTLBuffer, count : Int) -> [T]{
        return Array(UnsafeBufferPointer(start: buffer.contents().bindMemory(to: T.self, capacity: count), count: count))
    }
    
}
