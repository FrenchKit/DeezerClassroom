//
//  FastFloatVectorMath.swift
//  Knitstagram
//
//  Created by Adrien Coye de Brunélis on 15/02/2017.
//  Copyright © 2017 Adrien Coye de Brunélis. All rights reserved.
//

import Foundation
import Accelerate

typealias vFloat = Array<Float>

extension Collection where Iterator.Element == Float {
    
    func quickSum() -> Float {
        var result: Float = 0
        switch self {
        case let array as Array<Float>:
            vDSP_sve(array, vDSP_Stride(1), &result, vDSP_Length(array.count))
        case let slice as ArraySlice<Float>:
            vDSP_sve(Array(slice), vDSP_Stride(1), &result, vDSP_Length(slice.count))
        default:
            print("unknown collection type for quickSum of Float")
        }
        return result
    }
    
    func quickMean() -> Float {
        var result: Float = 0
        switch self {
        case let array as Array<Float>:
            vDSP_meanv(array, vDSP_Stride(1), &result, vDSP_Length(array.count))
        case let slice as ArraySlice<Float>:
            vDSP_meanv(Array(slice), vDSP_Stride(1), &result, vDSP_Length(slice.count))
        default:
            print("unknown collection type for quickSum of Float")
        }
        return result
    }
    
    func quickWeightedIncrementalAveraging(weight: Float,
                                     previousData: vFloat) -> vFloat {
        
        func _quickWeightedIncrementalAveraging(leftWeight: Float,
                                                leftVector: vFloat,
                                                rightVector: vFloat) -> vFloat {
            
            var lWeight: Float = leftWeight
            var rWeight: Float = 1.0-leftWeight
            var leftVectorWeighted = vFloat(repeating: 0.0, count: leftVector.count)
            var resultVector = vFloat(repeating: 0.0, count: leftVector.count)
            
            // weight left hand
            vDSP_vsmul(leftVector, vDSP_Stride(1), &lWeight, &leftVectorWeighted, vDSP_Stride(1), vDSP_Length(leftVector.count))
            
            // weight right hand and add left hand
            vDSP_vsma(rightVector, vDSP_Stride(1), &rWeight, &leftVectorWeighted, vDSP_Stride(1), &resultVector, vDSP_Stride(1), vDSP_Length(rightVector.count))
            
            return resultVector
        }
        
        var leftVector: vFloat {
            get {
                switch self {
                case let array as Array<Float>:
                    return array
                case let slice as ArraySlice<Float>:
                    return Array(slice)
                default:
                    print("unknown collection type for quickWeightedIncrementalAveraging")
                    return vFloat()
                }
            }
        }
    
        return _quickWeightedIncrementalAveraging(leftWeight: weight,
                                                  leftVector: leftVector,
                                                  rightVector: previousData)
    }
    
}

extension Collection where Iterator.Element == Double {
    
    func quickSum() -> Double {
        var result: Double = 0
        switch self {
        case let array as Array<Double>:
            vDSP_sveD(array, vDSP_Stride(1), &result, vDSP_Length(array.count))
        case let slice as ArraySlice<Double>:
            vDSP_sveD(Array(slice), vDSP_Stride(1), &result, vDSP_Length(slice.count))
        default:
            print("unknown collection type for quickSum of Double")
        }
        return result
    }
    
    func quickMean() -> Double {
        var result: Double = 0
        switch self {
        case let array as Array<Double>:
            vDSP_meanvD(array, vDSP_Stride(1), &result, vDSP_Length(array.count))
        case let slice as ArraySlice<Double>:
            vDSP_meanvD(Array(slice), vDSP_Stride(1), &result, vDSP_Length(slice.count))
        default:
            print("unknown collection type for quickMean of Double")
        }
        return result
    }
}
