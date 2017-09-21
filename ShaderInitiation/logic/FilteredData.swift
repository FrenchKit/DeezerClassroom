//
//  FilteredData.swift
//  ShaderInitiation
//
//  Created by adrien on 9/17/17.
//  Copyright © 2017 Adrien Coye de Brunélis. All rights reserved.
//

import GLKit

class FilteredData {

    var data: vFloat
    private let lowPassFilterRatio: Float
    private let maxRMSHistorySize = 64
    private var history: vFloat
    
    var historyVectorSmooth: GLKVector4 {
        get {
            return GLKVector4Make(history[0...3].quickMean(),
                                  history[4...7].quickMean(),
                                  history[8...11].quickMean(),
                                  history[12...15].quickMean())
        }
    }
    
    init(lowPassFilterRatio: Float) {
        data = vFloat()
        history = vFloat(repeating: 0.0, count: maxRMSHistorySize)
        self.lowPassFilterRatio = lowPassFilterRatio
    }
    
    func lastRMS() -> Float {
        return history[0]
    }
    
    func batchUpdate (input: vFloat) {
        
        // fastpath
        switch self.lowPassFilterRatio {
        case 0.0:
            self.data = vFloat(repeating: 0.0, count: input.count)
        case 1.0:
            self.data = input
        default:
            self.data = input.quickWeightedIncrementalAveraging(weight: self.lowPassFilterRatio, previousData: self.data)
        }
        
        computeRMS()
    }
    
    private func computeRMS() {
        let rms = data.quickMean()
        history.insert(rms, at: 0)
        while history.count >= maxRMSHistorySize {
            history.removeLast()
        }
    }
}
